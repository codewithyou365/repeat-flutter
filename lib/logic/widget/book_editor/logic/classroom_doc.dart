import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/json_splitter.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/classroom_doc_help.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';
import 'package:repeat_flutter/logic/reimport_help.dart';

import 'util.dart';

/// 网络编辑的"单位=课堂"：一次拿走/写回整个课堂（所有 book + chapter + verse）。
///
/// 和单本的 /book + /commit 是两套并行的入口，文档格式也不同：
/// 这里多一层 'b' 数组，数组里每本书的文档就是 /book 返回的那份，
/// 外加一个 'book' 元数据块（书名/排序/启用/url），见 [ClassroomDocField]。
///
/// 整份文档可能几十上百 MB，所以出去用 [ClassroomDocHelp.writeDoc] 流式写 response，
/// 回来先流式落盘再用 [JsonSplitter] 按书切开，一本一本处理，内存里始终只有一本书。

/// 课堂文档的乐观锁标记：课堂内容版本 + 每本书的缓存版本。
/// 任何一本书在 App 里或单本编辑器里被改过，这个串就变了，课堂提交会被挡下来。
Future<String> classroomCacheVersion(int classroomId) async {
  final classroom = await Db().db.classroomDao.getById(classroomId);
  final books = await Db().db.bookDao.getAll(classroomId);
  final bookPart = books.map((e) => '${e.id}:${e.contentVersion}').join(',');
  return '${classroom?.contentVersion ?? -1}|$bookPart';
}

Future<void> handleClassroomDoc(HttpRequest request, int defaultBookId) async {
  final response = request.response;
  final classroomId = await Util.getClassroomId(request, defaultBookId);
  if (classroomId == null) {
    response.statusCode = HttpStatus.internalServerError;
    response.write('Failed to get classroom.');
    await response.close();
    return;
  }

  try {
    response.headers.contentType = ContentType.json;
    response.headers.add(Header.classroomCacheVersion, await classroomCacheVersion(classroomId));
    final result = await ClassroomDocHelp.writeDoc(
      classroomId: classroomId,
      sink: response,
      rootUrl: null,
      note: true,
      databaseData: true,
    );
    if (result == null) {
      // 已经往 response 里写了半截 JSON，改不了状态码了，只能让前端解析失败
      response.write('"__error__":"Failed to get classroom doc."');
    }
  } catch (e) {
    response.write('"__error__":${jsonEncode(e.toString())}');
  }
  await response.close();
}

Future<void> handleClassroomCommit(HttpRequest request, int defaultBookId) async {
  final response = request.response;
  final classroomId = await Util.getClassroomId(request, defaultBookId);
  if (classroomId == null) {
    response.statusCode = HttpStatus.internalServerError;
    response.write('Failed to get classroom.');
    await response.close();
    return;
  }
  final versionHeader = request.headers[Header.classroomCacheVersion] ?? [];

  String? stagingPath;
  try {
    // 1. 请求体先流式落盘，不整份读进内存
    final rootPath = await DocPath.getContentPath();
    stagingPath = rootPath.joinPath('$classroomId').joinPath(commitStagingDir);
    await Folder.delete(stagingPath);
    await Folder.ensureExists(stagingPath);
    final rawFile = File(stagingPath.joinPath('raw.json'));
    final rawSink = rawFile.openWrite();
    await rawSink.addStream(request);
    await rawSink.close();

    // 2. 课堂入口只收课堂文档。这里"少一本书"是有语义的（见第 5 步），
    //    单本文档发到这里会被当成整个课堂只剩这一本，所以先把单位对上。
    final editUnit = Util.getEditUnit(request);
    if (editUnit != null && editUnit != EditUnit.classroom) {
      response.statusCode = HttpStatus.badRequest;
      response.write('Commit failed: this is the classroom endpoint but the document is "$editUnit".');
      return;
    }

    // 3. 版本一致才动库，和单本 /commit 一个规矩
    final currentVersion = await classroomCacheVersion(classroomId);
    if (versionHeader.isEmpty || versionHeader.first != currentVersion) {
      response.statusCode = HttpStatus.ok;
      response.write("Commit failed because the version is not consistent");
      return;
    }

    // 4. 按书切开，每本书一个文件
    final splitter = JsonSplitter(
      outDir: stagingPath.joinPath('books'),
      arrayKey: ClassroomDocField.books,
    );
    if (!await splitter.split(rawFile)) {
      response.statusCode = HttpStatus.badRequest;
      response.write('Commit failed: the document must be an object with a "${ClassroomDocField.books}" array.');
      return;
    }
    // 课堂文档的课堂内容就在顶层，不该再套一层 'cr'（那是单本文档的写法）
    if (splitter.head.containsKey(ClassroomDocField.classroom)) {
      response.statusCode = HttpStatus.badRequest;
      response.write('Commit failed: "${ClassroomDocField.classroom}" belongs to a single book document, the classroom content is already at the top level here.');
      return;
    }

    // 5. 先扫一遍每本书的 id：书本是不是本课堂的、有没有书被整本删掉。
    //    这些必须在动库之前查清楚，不然改到一半才发现就回不去了。
    final existingBooks = await Db().db.bookDao.getAll(classroomId);
    final existingIds = existingBooks.map((e) => e.id!).toSet();
    final List<int?> bookIds = [];
    final Set<int> keptIds = {};
    for (final path in splitter.elementPaths) {
      final doc = jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      final id = doc[ClassroomDocField.bookId] as int?;
      bookIds.add(id);
      if (id == null) {
        continue;
      }
      if (!existingIds.contains(id)) {
        response.statusCode = HttpStatus.badRequest;
        response.write('Commit failed: book id $id does not belong to this classroom.');
        return;
      }
      if (!keptIds.add(id)) {
        response.statusCode = HttpStatus.badRequest;
        response.write('Commit failed: book id $id appears more than once.');
        return;
      }
    }
    final removed = existingIds.difference(keptIds);
    if (removed.isNotEmpty) {
      // 删书会连带删掉媒体文件、学习进度和复习记录，代价太大，不让在 JSON 里漏一行就删掉
      response.statusCode = HttpStatus.badRequest;
      response.write('Commit failed: book ${removed.join(",")} is missing. Please delete books in the app.');
      return;
    }

    // 6. 课堂自己的内容。'g[].d' 是游戏数据，摘出来写回 Game 表，不进 content。
    await ClassroomDocHelp.takeGameData(classroomId, splitter.head);
    await Db().db.classroomDao.updateContent(classroomId, jsonEncode(splitter.head));

    // 7. 一本一本落库
    final List<Map<String, dynamic>> results = [];
    for (var i = 0; i < splitter.elementPaths.length; i++) {
      final doc = jsonDecode(await File(splitter.elementPaths[i]).readAsString()) as Map<String, dynamic>;
      var bookId = bookIds[i];

      if (bookId == null) {
        // 新书：没给 'i' 就是要新建一本，书名从内容的 'n' 里取
        final name = doc[bookNameKey] as String? ?? '';
        if (name.isEmpty) {
          response.statusCode = HttpStatus.badRequest;
          response.write('Commit failed: a new book needs a name in "$bookNameKey".');
          return;
        }
        // 重名会直接抛，落到下面的 catch 里返回 400
        bookId = (await Db().db.bookDao.addTo(classroomId, name)).id!;
      }

      // 书名就在 content 的 'n' 里，reimport 写 content 时一并落库，不用另外改元数据
      final result = await ReimportHelp.reimport(bookId, doc);
      if (result == null) {
        response.statusCode = HttpStatus.expectationFailed;
        response.write('Commit failed at book $bookId.');
        return;
      }
      results.add({'bookId': bookId, ...result.toJson()});
    }

    response.statusCode = HttpStatus.ok;
    response.write("Commit successful.\n${JsonEncoder.withIndent(' ').convert(results)}");
  } catch (e, st) {
    response.statusCode = HttpStatus.badRequest;
    response.write("Error : $e\n$st");
  } finally {
    if (stagingPath != null) {
      // 切出来的分册删掉，raw.json 留着：课堂文档太大不适合进 EditBookHistory，
      // 提交失败时这份原稿就是唯一的底稿。
      await Folder.delete(stagingPath.joinPath('books'));
    }
    await response.close();
  }
}

/// 课堂提交时请求体和切分结果的落脚点
const String commitStagingDir = '__commit';
