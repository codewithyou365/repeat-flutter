import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart' show MimeMultipartTransformer;
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

import 'util.dart';

Future<void> handleUpload(HttpRequest request, Directory? dir) async {
  dir = await Util.getDir(request, dir);
  if (dir == null) {
    request.response.statusCode = HttpStatus.internalServerError;
    await request.response.close();
    return;
  }

  try {
    final contentType = request.headers.contentType;
    if (contentType == null || !contentType.mimeType.startsWith('multipart/')) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final transformer = MimeMultipartTransformer(contentType.parameters['boundary']!);
    final bodyStream = request.cast<List<int>>();
    await for (final part in transformer.bind(bodyStream)) {
      final contentDisposition = part.headers['content-disposition'];
      if (contentDisposition == null || !contentDisposition.contains('filename=')) {
        continue;
      }

      final filename = RegExp(r'filename="([^"]+)"').firstMatch(contentDisposition)?.group(1) ?? 'upload.tmp';

      final tempFile = File(p.join(dir.path, filename));
      final sink = tempFile.openWrite();
      await part.pipe(sink);
      await sink.close();

      final fileHash = await Hash.toSha1(tempFile.path);
      final dc = DownloadContent(url: filename, hash: fileHash);

      final folderPath = p.join(dir.path, dc.folder);
      await Directory(folderPath).create(recursive: true);

      final finalPath = p.join(folderPath, dc.name);
      await tempFile.rename(finalPath);

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(dc.path);
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.badRequest;
    await request.response.close();
  } catch (e, st) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'error': e.toString(), 'stack': st.toString()}));
    await request.response.close();
  }
}
