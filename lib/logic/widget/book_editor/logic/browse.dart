import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/classroom_doc_help.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

import 'util.dart';

Future<void> handleBrowse(HttpRequest request, Directory? dir) async {
  dir = await Util.getFilesDir(request, dir);
  if (dir == null) {
    request.response.statusCode = HttpStatus.internalServerError;
    return;
  }

  try {
    final list = await find(dir);
    request.response
      ..headers.contentType = ContentType.json
      ..write(json.encode(list));
  } catch (e) {
    request.response.statusCode = HttpStatus.internalServerError;
  }
  request.response.close();
}

Future<List<String>> find(Directory dir) async {
  return await _find(dir, dir.path.length + 1);
}

Future<List<String>> _find(Directory dir, int rootSize) async {
  final files = <String>[];
  final dirs = <Directory>[];

  await for (final entity in dir.list(followLinks: false)) {
    final relativePath = entity.path.substring(rootSize);
    if (entity is File) {
      files.add(relativePath);
    } else if (entity is Directory) {
      dirs.add(entity);
    }
  }

  for (final subDir in dirs) {
    files.addAll(await _find(subDir, rootSize));
  }

  return files;
}

/// 清理没人引用的文件。
///
/// 目录是整个课堂共用的，所以有用的文件必须是**全课堂的并集**：每一本书的引用
/// 加上课堂自己的 'd'（游戏 zip、提示的字体和提示服务 zip）。
/// 只按当前这本书算的话，会把别的书和游戏的文件全删光。
Future<void> handleRemoveUselessFiles(HttpRequest request, int defaultBookId, Directory? dir) async {
  final classroomId = await Util.getClassroomId(request, defaultBookId);
  dir = await Util.getFilesDir(request, dir);

  if (dir == null || classroomId == null) {
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.close();
    return;
  }

  final List<DownloadContent> dcs = [];
  final books = await Db().db.bookDao.getAll(classroomId);
  for (final book in books) {
    Map<String, dynamic> docMap = {};
    bool success = await DocHelp.getDocMapFromDb(
      bookId: book.id!,
      ret: docMap,
      rootUrl: null,
      note: true,
      databaseData: true,
    );
    if (!success || docMap.isEmpty) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.close();
      return;
    }
    dcs.addAll(DocHelp.getDownloads(BookContent.fromJson(docMap)));
  }
  dcs.addAll(await ClassroomDocHelp.classroomDownloads(classroomId));

  final Set<String> usefulFiles = dcs.map((d) => d.path).toSet();
  // The zip of a game/tip is unzipped into a folder next to it, named by its hash.
  // Those unzipped files are not in the download list, so keep them by prefix.
  final List<String> usefulDirs = dcs.map((d) => '${d.folder}/${d.pureName}/').toList();
  try {
    final existingFiles = await find(dir);

    for (final relativePath in existingFiles) {
      final normalizedPath = relativePath.replaceAll(Platform.pathSeparator, '/');
      if (usefulDirs.any((prefix) => normalizedPath.startsWith(prefix))) {
        continue;
      }
      if (!usefulFiles.contains(relativePath)) {
        final fileToDelete = File('${dir.path}${Platform.pathSeparator}$relativePath');
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
        }
      }
    }

    request.response.statusCode = HttpStatus.ok;
    request.response.write(
      json.encode({
        'status': 'success',
        'message': 'Cleanup complete',
      }),
    );
  } catch (e) {
    request.response.statusCode = HttpStatus.internalServerError;
  } finally {
    await request.response.close();
  }
}
