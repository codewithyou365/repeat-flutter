import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/json_splitter.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/import_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 导入一整个课堂（zip 或远程）。
///
/// **只往空课堂里导**：课堂由用户先建好（名字也是用户起的），里面一本书都没有才允许导入，
/// 所以绝不会合并进已有内容、碰到已有的学习进度。失败时清空回滚，课堂本身留着。
///
/// 整份 index.json 可能几十上百 MB，所以先用 [JsonSplitter] 按书切成一堆小文件，
/// 再一本一本交给现有的 [ImportHelp.import]，内存里始终只有一本书。
class ClassroomImportHelp {
  /// 导入过程中的暂存目录，放在课堂目录下，成功/失败都会删掉
  static const String stagingDir = '__import';

  static Future<ClassroomImportResult?> fromZip({
    required String zipPath,
    required int classroomId,
    String? password,
    void Function(int done, int total)? onProgress,
  }) async {
    return _run(
      classroomId: classroomId,
      onProgress: onProgress,
      prepare: (classroomId, stagingPath) async {
        await Zip.uncompressStream(File(zipPath), stagingPath, password: password);
        final zipRoot = await ZipRootDoc.fromPath(stagingPath.joinPath(DocPath.zipRootFile));
        return _Source(
          indexFile: File(stagingPath.joinPath(DocPath.getIndexFileName())),
          url: zipRoot?.url ?? '',
          // zip 里所有文件（书本的和课堂的）都平铺在 DocPath.classroomFiles 下，整个目录搬过去就行
          mediaDir: stagingPath.joinPath(DocPath.classroomFiles),
        );
      },
    );
  }

  static Future<ClassroomImportResult?> fromUrl({
    required String url,
    required int classroomId,
    String credentials = '',
    void Function(int done, int total)? onProgress,
    DownloadProgressCallback? downloadProgress,
  }) async {
    return _run(
      classroomId: classroomId,
      onProgress: onProgress,
      prepare: (classroomId, stagingPath) async {
        final indexPath = DocPath.getClassroomRelativePath(classroomId).joinPath(stagingDir).joinPath(DocPath.getIndexFileName());
        final result = await DownloadDoc.start(
          url,
          indexPath,
          credentials: credentials,
          progressCallback: downloadProgress,
          skipSsl: true,
        );
        if (result != DownloadDocResult.success) {
          return null;
        }
        return _Source(
          indexFile: File(stagingPath.joinPath(DocPath.getIndexFileName())),
          url: url,
          credentials: credentials,
          downloadProgress: downloadProgress,
        );
      },
    );
  }

  static Future<ClassroomImportResult?> _run({
    required int classroomId,
    required Future<_Source?> Function(int classroomId, String stagingPath) prepare,
    void Function(int done, int total)? onProgress,
  }) async {
    final classroom = await Db().db.classroomDao.getById(classroomId);
    if (classroom == null) {
      Snackbar.show(I18nKey.labelClassroomImportFail.trArgs(['classroom $classroomId not found']));
      return null;
    }
    // 回滚会清空整个课堂，里面已经有书的话绝不能动
    if ((await Db().db.bookDao.getAll(classroomId)).isNotEmpty) {
      Snackbar.show(I18nKey.labelClassroomImportFail.trArgs(['classroom ${classroom.name} is not empty']));
      return null;
    }
    final rootPath = await DocPath.getContentPath();
    final classroomPath = rootPath.joinPath(DocPath.getClassroomRelativePath(classroom.id));
    final stagingPath = classroomPath.joinPath(stagingDir);

    try {
      await Folder.delete(stagingPath);
      await Folder.ensureExists(stagingPath);

      final source = await prepare(classroom.id, stagingPath);
      if (source == null) {
        throw Exception(I18nKey.labelDataAnomaly.trArgs(['index.json']));
      }

      // 按书切开：head 是课堂自己的内容，每本书一个文件
      final splitter = JsonSplitter(
        outDir: stagingPath.joinPath('books'),
        arrayKey: ClassroomDocField.books,
      );
      if (!await splitter.split(source.indexFile)) {
        throw Exception(I18nKey.labelDataAnomalyWithArg.trArgs(['classroom index.json']));
      }
      await Db().db.classroomDao.updateContent(classroom.id, jsonEncode(splitter.head));
      // zip 导入的话这一步就把全课堂的文件都搬完了，后面每本书不用再管文件
      await _importFiles(
        classroomId: classroom.id,
        head: splitter.head,
        rootPath: rootPath,
        source: source,
      );

      final total = splitter.elementPaths.length;
      for (var i = 0; i < total; i++) {
        await _importOneBook(
          classroomId: classroom.id,
          index: i,
          bookDocPath: splitter.elementPaths[i],
          rootPath: rootPath,
          source: source,
        );
        onProgress?.call(i + 1, total);
      }

      await Folder.delete(stagingPath);
      return ClassroomImportResult(classroom: classroom, bookCount: total);
    } catch (e, st) {
      debugPrint('classroom import failed: $e\n$st');
      // 不留半个课堂：数据和目录都清掉，课堂回到导入前的空课堂
      await Db().db.classroomDao.clearAll(classroom.id);
      await Folder.delete(classroomPath);
      Snackbar.show(I18nKey.labelClassroomImportFail.trArgs([e.toString()]));
      return null;
    }
  }

  /// 全课堂的文件（书本媒体、游戏 zip、提示的字体和提示服务 zip）都落在同一个 f 目录：
  /// zip 导入就整个目录搬过来，远程导入按课堂自己的 'd' 逐个下载（书本的 'd' 见 [_downloadMedia]）。
  static Future<void> _importFiles({
    required int classroomId,
    required Map<String, dynamic> head,
    required String rootPath,
    required _Source source,
  }) async {
    final filesRelativePath = DocPath.getFilesRelativePathOf(classroomId);
    final filesPath = rootPath.joinPath(filesRelativePath);

    final mediaDir = source.mediaDir;
    if (mediaDir != null) {
      if (await Directory(mediaDir).exists()) {
        await Folder.ensureExists(filesPath);
        await _moveInto(mediaDir, filesPath);
      }
      return;
    }

    final downloads = DownloadContent.toList(head['d']) ?? [];
    if (downloads.isEmpty) {
      return;
    }
    // 'r' 是对方给的课堂媒体根地址；没有就按 index.json 所在目录推
    final rootUrl = head['r'] as String? ?? source.url.substring(0, source.url.lastIndexOf("/"));
    for (final d in downloads) {
      final url = d.url.startsWith('http') ? d.url : rootUrl.joinPath(d.url);
      final result = await DownloadDoc.start(
        url,
        filesRelativePath.joinPath(d.path),
        credentials: source.credentials,
        hash: d.hash,
        progressCallback: source.downloadProgress,
        skipSsl: true,
      );
      if (result != DownloadDocResult.success) {
        throw Exception(I18nKey.labelDataAnomalyWithArg.trArgs([url]));
      }
    }
  }

  static Future<void> _importOneBook({
    required int classroomId,
    required int index,
    required String bookDocPath,
    required String rootPath,
    required _Source source,
  }) async {
    final bookDoc = jsonDecode(await File(bookDocPath).readAsString()) as Map<String, dynamic>;
    // 书名就在内容的 'n' 里；老的单本文档没有名字，按顺序编一个
    var name = bookDoc[bookNameKey] as String? ?? '';
    if (name.isEmpty) {
      name = 'book${index + 1}';
      bookDoc[bookNameKey] = name;
      await File(bookDocPath).writeAsString(jsonEncode(bookDoc));
    }

    final book = await Db().db.bookDao.addTo(classroomId, name);

    // zip 导入的文件已经在 _importFiles 里整个搬完了，只有远程导入才逐本下载
    if (source.mediaDir == null) {
      await _downloadMedia(
        bookDoc: bookDoc,
        filesPath: DocPath.getFilesRelativePathOf(classroomId),
        source: source,
      );
    }

    // 书本没有自己的目录，这份文档就是 JsonSplitter 切出来的暂存文件，导入完随暂存目录一起删
    final docRelativePath = bookDocPath.substring(rootPath.length + 1);

    // desc / sort / enable / url 不在文档里，走 addTo 给的默认值，
    // ImportHelp 会把 url 设成来源地址、书本置为启用。
    if (!await ImportHelp.import(book.id!, source.url, docRelativePath)) {
      throw Exception(I18nKey.labelDataAnomalyWithArg.trArgs(['book $name']));
    }
  }

  static Future<void> _downloadMedia({
    required Map<String, dynamic> bookDoc,
    required String filesPath,
    required _Source source,
  }) async {
    final content = BookContent.fromJson(bookDoc);
    final rootUrl = source.url.substring(0, source.url.lastIndexOf("/"));
    final downloads = DocHelp.getDownloads(content, rootUrl: rootUrl);
    for (final d in downloads) {
      final result = await DownloadDoc.start(
        d.url,
        filesPath.joinPath(d.path),
        credentials: source.credentials,
        hash: d.hash,
        progressCallback: source.downloadProgress,
        skipSsl: true,
      );
      if (result != DownloadDocResult.success) {
        throw Exception(I18nKey.labelDataAnomalyWithArg.trArgs([d.url]));
      }
    }
  }

  /// 把 [from] 目录下的东西整个搬到 [to]，搬完删掉 [from]
  static Future<void> _moveInto(String from, String to) async {
    final dir = Directory(from);
    if (!await dir.exists()) {
      return;
    }
    await for (final entity in dir.list()) {
      final target = to.joinPath(entity.uri.pathSegments.where((e) => e.isNotEmpty).last);
      if (entity is Directory) {
        await Folder.delete(target);
        await entity.rename(target);
      } else if (entity is File) {
        await entity.rename(target);
      }
    }
    await Folder.delete(from);
  }
}

class ClassroomImportResult {
  final Classroom classroom;
  final int bookCount;

  ClassroomImportResult({required this.classroom, required this.bookCount});
}

/// 课堂内容从哪来：zip 是本地目录，远程是一串 URL
class _Source {
  final File indexFile;
  final String url;
  final String credentials;
  final DownloadProgressCallback? downloadProgress;

  /// zip 导入时 zip 里存文件的那个目录（全课堂平铺一份）；远程导入为 null（改成逐个下载）
  final String? mediaDir;

  _Source({
    required this.indexFile,
    required this.url,
    this.credentials = '',
    this.downloadProgress,
    this.mediaDir,
  });
}
