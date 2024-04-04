import 'dart:io';

String urlToFileName(String urlPath) {
  var ret = urlPath.split("/").last;
  return ret;
}

String urlToRootPath(String urlPath) {
  var ret = urlPath.split("://").last;
  var firstIndex = ret.indexOf("/");
  var lastIndex = ret.lastIndexOf("/");
  if (firstIndex == lastIndex) {
    return "";
  }
  ret = ret.substring(0, lastIndex);
  return ret.substring(firstIndex);
}

extension StringExtension on String {
  String joinPath(String path) {
    if (path == "") {
      return this;
    } else if (path.startsWith("/")) {
      return "$this$path";
    } else {
      return "$this/$path";
    }
  }
}

class FileLocation {
  String folderPath;
  String fileName;

  get path => "$folderPath/$fileName";

  FileLocation(this.folderPath, this.fileName);

  static FileLocation create(String path) {
    var folderPath = path.substring(0, path.lastIndexOf("/"));
    var fileName = path.split("/").last;
    return FileLocation(folderPath, fileName);
  }
}

Future<bool> folderExists(String path) async {
  try {
    final directory = Directory(path);
    return await directory.exists();
  } on FileSystemException catch (_) {
    return false;
  }
}

Future<void> ensureFolderExists(String path) async {
  try {
    final directory = Directory(path);
    var exists = await directory.exists();
    if (!exists) {
      await directory.create(recursive: true);
    }
  } on FileSystemException catch (_) {}
}
