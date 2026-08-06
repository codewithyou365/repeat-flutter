import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';

class ZipArchive {
  final String path;
  File? file;
  Uint8List? bytes;

  ZipArchive({required this.path, this.file, this.bytes});
}

/// Thrown when a zip cannot be decrypted: wrong password, or no password
/// given for an encrypted zip.
class ZipPasswordException implements Exception {}

class Zip {
  /// Reads only the central directory, so it never decrypts any content and
  /// works on an encrypted zip without a password.
  static Future<bool> isEncrypted(File zipFile) async {
    final input = InputFileStream(zipFile.path);
    try {
      final decoder = ZipDecoder();
      decoder.decodeStream(input);
      return decoder.directory.fileHeaders.any((h) => h.generalPurposeBitFlag & 0x1 != 0);
    } catch (_) {
      return false;
    } finally {
      await input.close();
    }
  }

  static Future<void> uncompress(File zipFile, String destinationDir, {String? password}) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, password: password);
    final directory = Directory(destinationDir);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    for (final file in archive) {
      final filename = file.name;
      final filePath = '${directory.path}/$filename';

      if (file.isFile) {
        final List<int> content;
        try {
          content = file.content as List<int>;
        } catch (e) {
          if (_isPasswordError(e)) {
            throw ZipPasswordException();
          }
          rethrow;
        }
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(content);
      } else {
        final dir = Directory(filePath);
        await dir.create(recursive: true);
      }
    }
  }

  /// 流式解包：一个文件一个文件地写到磁盘。
  /// [uncompress] 会把整个 zip 读进内存，课堂级导入（几百 MB）必须用这个。
  static Future<void> uncompressStream(File zipFile, String destinationDir, {String? password}) async {
    final input = InputFileStream(zipFile.path);
    try {
      final archive = ZipDecoder().decodeStream(input, password: password);
      for (final file in archive) {
        final filePath = '$destinationDir/${file.name}';
        if (!file.isFile) {
          await Directory(filePath).create(recursive: true);
          continue;
        }
        await File(filePath).parent.create(recursive: true);
        final output = OutputFileStream(filePath);
        try {
          file.writeContent(output);
        } catch (e) {
          if (_isPasswordError(e)) {
            throw ZipPasswordException();
          }
          rethrow;
        } finally {
          await output.close();
        }
      }
    } finally {
      await input.close();
    }
  }

  static Future<File> compress(List<ZipArchive> files, File zipFile, {String? password}) async {
    final archive = Archive();

    for (var file in files) {
      final bytes = file.bytes ?? await file.file!.readAsBytes();
      final archiveFile = ArchiveFile(file.path, bytes.length, bytes);
      archive.addFile(archiveFile);
    }

    final zipEncoder = ZipEncoder(password: (password?.isEmpty ?? true) ? null : password);
    final zipData = zipEncoder.encode(archive);

    await zipFile.writeAsBytes(zipData);

    return zipFile;
  }

  /// 流式打包：一个文件一个文件地写进 zip。
  /// [compress] 会把所有内容和整个归档都堆在内存里，课堂级导出（几百 MB 媒体）必须用这个。
  static Future<File> compressStream(List<ZipArchive> files, File zipFile, {String? password}) async {
    final encoder = ZipFileEncoder(password: (password?.isEmpty ?? true) ? null : password);
    encoder.create(zipFile.path);
    try {
      for (final f in files) {
        if (f.file != null) {
          await encoder.addFile(f.file!, f.path);
        } else if (f.bytes != null) {
          final bytes = f.bytes!;
          encoder.addArchiveFile(ArchiveFile(f.path, bytes.length, bytes));
        }
      }
    } finally {
      await encoder.close();
    }
    return zipFile;
  }

  /// The archive package signals decryption failure with a plain Exception, and
  /// a missing password with a null-check error on its internal password field.
  static bool _isPasswordError(Object e) {
    if (e is TypeError) {
      return true;
    }
    final msg = e.toString();
    return msg.contains('password error') || msg.contains("macs don't match");
  }
}
