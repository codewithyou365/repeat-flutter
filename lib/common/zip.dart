import 'dart:io';

import 'package:archive/archive.dart';

class ZipArchive {
  final File file;
  final String path;

  ZipArchive(this.file, this.path);
}

class Zip {
  static Future<void> uncompress(File zipFile, String destinationDir) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final directory = Directory(destinationDir);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    for (final file in archive) {
      final filename = file.name;
      final filePath = '${directory.path}/$filename';

      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        final dir = Directory(filePath);
        await dir.create(recursive: true);
      }
    }

    print('Files extracted to ${directory.path}');
  }

  static Future<File> compress(List<ZipArchive> files, File zipFile) async {
    final archive = Archive();

    for (var file in files) {
      final bytes = await file.file.readAsBytes();
      final archiveFile = ArchiveFile(file.path, bytes.length, bytes);
      archive.addFile(archiveFile);
    }

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    await zipFile.writeAsBytes(zipData!);

    return zipFile;
  }
}
