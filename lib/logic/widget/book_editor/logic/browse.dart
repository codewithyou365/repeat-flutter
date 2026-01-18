import 'dart:convert';
import 'dart:io';

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

  // Recursively find files in subdirectories
  for (final subDir in dirs) {
    files.addAll(await _find(subDir, rootSize));
  }

  return files;
}
