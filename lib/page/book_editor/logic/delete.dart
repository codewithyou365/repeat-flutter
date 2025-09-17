import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> handleDelete(HttpRequest request, Directory? dir) async {
  final response = request.response;
  if (dir == null) {
    response.statusCode = HttpStatus.internalServerError;
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
    if (await file.exists()) {
      await file.delete();
      response.statusCode = HttpStatus.ok;
      response.write('Delete success');
    } else {
      response.statusCode = HttpStatus.notFound;
      response.write('Not Found');
    }
    await response.close();
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
  }
}
