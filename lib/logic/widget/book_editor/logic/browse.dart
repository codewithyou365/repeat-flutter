import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

import 'util.dart';

Future<void> handleBrowse(HttpRequest request, Directory? dir) async {
  dir = await Util.getDir(request, dir);
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

Future<void> handleRemoveUselessFiles(HttpRequest request, int bookId, Directory? dir) async {
  bookId = await Util.getBookId(request, bookId);
  dir = await Util.getDir(request, dir);

  if (dir == null) {
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.close();
    return;
  }
  Map<String, dynamic> docMap = {};
  bool success = await DocHelp.getDocMapFromDb(
    bookId: bookId,
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
  BookContent kv = BookContent.fromJson(docMap);
  final dcs = DocHelp.getDownloads(kv);
  final Set<String> usefulFiles = dcs.map((d) => d.path).toSet();
  try {
    final existingFiles = await find(dir);

    for (final relativePath in existingFiles) {
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
