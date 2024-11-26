import 'dart:io';

class FileUtil {
  static Future<void> copy(String source, String destination) async {
    final sourceFile = File(source);

    try {
      await sourceFile.copy(destination);
    } catch (e) {
      print('Failed to copy file: $e');
    }
  }
}