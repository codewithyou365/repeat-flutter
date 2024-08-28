import 'dart:io';

class Folder {
  static Future<bool> exists(String path) async {
    try {
      final directory = Directory(path);
      return await directory.exists();
    } on FileSystemException catch (_) {
      return false;
    }
  }

  static Future<void> ensureExists(String path) async {
    try {
      final directory = Directory(path);
      var exists = await directory.exists();
      if (!exists) {
        await directory.create(recursive: true);
      }
    } on FileSystemException catch (_) {}
  }

  static Future<void> delete(String path) async {
    try {
      final directory = Directory(path);
      var exists = await directory.exists();
      if (exists) {
        await directory.delete(recursive: true);
      }
    } on FileSystemException catch (_) {}
  }
}
