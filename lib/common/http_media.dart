import 'dart:io';

class HttpMedia {
  static Future<void> play(HttpRequest request, File file) async {
    final response = request.response;
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Range');
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
      response.headers.contentType = ContentType('audio', 'mpeg');
    }
    response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

    if (isPartial) {
      response.statusCode = HttpStatus.partialContent;
      response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$fileLength');
      response.headers.set(HttpHeaders.contentLengthHeader, contentLength);
    } else {
      response.statusCode = HttpStatus.ok;
      response.headers.set(HttpHeaders.contentLengthHeader, fileLength);
    }

    try {
      final stream = file.openRead(start, end + 1);
      await stream.pipe(response);
    } catch (e) {
      print('Stream write error: $e');
    }
  }
}
