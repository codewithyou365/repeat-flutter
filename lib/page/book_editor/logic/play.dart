import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> handlePlay(HttpRequest request, Directory? dir) async {
  final response = request.response;
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
      await _playMedia(request, file);
    } else {
      response.headers.contentType = ContentType.binary;

      final fileName = p.basename(file.path);
      response.headers.set('content-disposition', 'attachment; filename="${Uri.encodeComponent(fileName)}"');

      await file.openRead().pipe(response);
    }
  } catch (e, st) {
    print('Error serving media: $e\n$st');
    response.statusCode = HttpStatus.internalServerError;
    await response.close();
  }
}

Future<void> _playMedia(HttpRequest request, File file) async {
  final response = request.response;
  final fileLength = await file.length();
  final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

  int start = 0;
  int end = fileLength - 1;
  bool isPartial = false;

  if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
    final range = rangeHeader.substring(6).split('-');
    start = int.tryParse(range[0]) ?? 0;
    if (range.length > 1 && range[1].isNotEmpty) {
      end = int.tryParse(range[1]) ?? end;
    }
    if (start < 0 || start >= fileLength) start = 0;
    if (end >= fileLength) end = fileLength - 1;
    isPartial = true;
  }

  final contentLength = end - start + 1;
  if (file.path.toLowerCase().endsWith('.mp4')) {
    response.headers.contentType = ContentType('video', 'mp4');
  } else {
    response.headers.contentType = ContentType('audio', 'mp3');
  }
  response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

  if (isPartial) {
    response.statusCode = HttpStatus.partialContent;
    response.headers.set(
      HttpHeaders.contentRangeHeader,
      'bytes $start-$end/$fileLength',
    );
    response.headers.set(HttpHeaders.contentLengthHeader, contentLength);
  } else {
    response.headers.set(HttpHeaders.contentLengthHeader, fileLength);
  }

  final stream = file.openRead(start, end + 1);
  await stream.pipe(response);
}
