import 'dart:io';

String urlToDocName(String urlPath) {
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
    } else if (path.startsWith("/") && this.endsWith("/")) {
      return "$this${path.substring(1)}";
    } else if (!path.startsWith("/") && !this.endsWith("/")) {
      return "$this/$path";
    } else {
      return "$this$path";
    }
  }
}

class DocLocation {
  String folderPath;
  String fileName;

  get path => "$folderPath/$fileName";

  DocLocation(this.folderPath, this.fileName);

  static DocLocation create(String path) {
    var folderPath = path.substring(0, path.lastIndexOf("/"));
    var fileName = path.split("/").last;
    return DocLocation(folderPath, fileName);
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
