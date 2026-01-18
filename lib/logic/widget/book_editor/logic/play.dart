import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:repeat_flutter/common/http_media.dart';

import 'util.dart';

Set<String> activeDownloads = {};

void clearActiveDownloads() {
  activeDownloads = {};
}

Future<void> handleCheckDownloadStatus(HttpRequest request) async {
  final response = request.response;
  final id = request.uri.queryParameters['id'];

  if (id == null || id.isEmpty) {
    response.statusCode = HttpStatus.badRequest;
    response.write('Missing "id" parameter');
    await response.close();
    return;
  }

  final status = activeDownloads.contains(id) ? 'in_progress' : 'done';
  response.headers.contentType = ContentType.json;
  response.write(json.encode({'status': status}));
  await response.close();
}

Future<void> handlePlay(HttpRequest request, Directory? dir) async {
  final response = request.response;
  dir = await Util.getDir(request, dir);
  if (dir == null) {
    response.statusCode = HttpStatus.internalServerError;
    await response.close();
    return;
  }

  try {
    final pathParam = request.uri.queryParameters['path'];
    if (pathParam == null || pathParam.isEmpty) {
      response.statusCode = HttpStatus.badRequest;
      response.write('Missing "path" parameter');
      await response.close();
      return;
    }

    final filePath = p.join(dir.path, pathParam);
    final file = File(filePath);

    if (!await file.exists()) {
      response.statusCode = HttpStatus.notFound;
      response.write('File not found');
      await response.close();
      return;
    }

    if (file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mp3')) {
      await HttpMedia.play(request, file);
    } else {
      final id = request.uri.queryParameters['id'];
      if (id == null || id.isEmpty) {
        response.statusCode = HttpStatus.badRequest;
        response.write('Missing "id" parameter for download');
        await response.close();
        return;
      }

      activeDownloads.add(id);
      response.headers.contentType = ContentType.binary;

      final fileName = p.basename(file.path);
      response.headers.set('content-disposition', 'attachment; filename="${Uri.encodeComponent(fileName)}"');

      try {
        await file.openRead().pipe(response);
      } finally {
        activeDownloads.remove(id);
      }
    }
  } catch (e, st) {
    print('Error serving media: $e\n$st');
    response.statusCode = HttpStatus.internalServerError;
    await response.close();
  }
}
