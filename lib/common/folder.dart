import 'dart:io';

import 'package:flutter/material.dart';

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

 static Future<bool> deleteIfEmpty(String path) async {
    final dir = Directory(path);

    try {
      if (!await dir.exists()) return false;

      bool hasFile = await dir.list(recursive: true).any((fse) => fse is File);

      if (!hasFile) {
        await dir.delete(recursive: true);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Error handling directory $path: $e");
      return false;
    }
  }
}
