import 'dart:io';

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
