import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repeat_flutter/common/file_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/logic/upload.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'sc_settings_data_state.dart';

typedef DialogCallback = void Function(BuildContext context, String url, String? mojo);

class ScSettingsDataLogic extends GetxController {
  final ScSettingsDataState state = ScSettingsDataState();

  @override
  void onInit() async {
    super.onInit();
    Kv? exportUrl = await Db().db.kvDao.one(K.exportUrl);
    state.exportUrl = exportUrl?.value ?? "";
    Kv? importUrl = await Db().db.kvDao.one(K.importUrl);
    state.importUrl = importUrl?.value ?? "";
  }

  void databaseExport(BuildContext context, String url, String? mojo) async {
    showOverlay(() async {
      state.exportUrl = url;
      await Db().db.kvDao.insertOrReplace(Kv(K.exportUrl, url));
      var path = await sqflite.getDatabasesPath();
      var res = await upload(url, path.joinPath(Db.fileName), Db.fileName);
      Get.back();
      Snackbar.show(res.data.toString());
    }, I18nKey.labelExporting.tr);
  }

  void allExport(BuildContext context) async {
    String? selectedDirectory;

    await showOverlay(() async {
      var permissionStatus = await Permission.manageExternalStorage.request();
      if (permissionStatus != PermissionStatus.granted) {
        Get.back();
        Snackbar.show(I18nKey.labelStoragePermissionDenied.tr);
        return;
      }

      final rawDb = Db().db.database;
      var rootPath = await DocPath.getContentPath();
      var dbDir = await sqflite.getDatabasesPath();
      var dbPath = dbDir.joinPath(Db.fileName);
      List<ZipArchive> allZips = [];

      allZips.add(ZipArchive(path: Db.fileName, file: File(dbPath)));

      List<Map<String, dynamic>> bookRows;
      try {
        bookRows = await rawDb.rawQuery('SELECT * FROM Book');
      } catch (e) {
        bookRows = [];
      }

      for (var bookRow in bookRows) {
        final bookId = bookRow['id'] as int;
        final classroomId = bookRow['classroomId'] as int;
        final contentUrl = (bookRow['url'] as String?) ?? '';

        Map<String, dynamic> docMap = {};
        bool success = await DocHelp.getDocMapFromDb(bookId: bookId, ret: docMap, rootUrl: null, note: true, databaseData: true);
        if (!success) continue;

        var downloads = DocHelp.getDownloads(BookContent.fromJson(docMap));
        if (downloads.isEmpty) continue;

        String relativePath = '$classroomId/$bookId';
        String zipFileName = '${classroomId}_$bookId.zip';
        File zipFile = File(rootPath.joinPath(relativePath).joinPath(zipFileName));

        final receivePort = ReceivePort();
        await Isolate.spawn(_createZipFileInIsolate, {
          'sendPort': receivePort.sendPort,
          'downloads': downloads,
          'zipFilePath': zipFileName,
          'relativePath': relativePath,
          'rootPath': rootPath,
          'contentUrl': contentUrl,
        });
        final result = await receivePort.first as Map<String, dynamic>;
        if (result['error'] != null) continue;

        allZips.add(ZipArchive(path: zipFileName, file: zipFile));
      }

      String timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '').substring(0, 15);
      String finalZipName = 'all_export_$timestamp.zip';
      File finalZipFile = File(rootPath.joinPath(finalZipName));
      await Zip.compress(allZips, finalZipFile);

      selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: I18nKey.labelSelectDirectoryToSave.trArgs([finalZipName]),
      );

      if (selectedDirectory != null) {
        try {
          finalZipFile.copySync(selectedDirectory!.joinPath(finalZipName));
          Get.back();
          Snackbar.show(I18nKey.labelSaveSuccess.trArgs([finalZipName]));
        } catch (e) {
          Snackbar.show(I18nKey.labelDirectoryPermissionDenied.trArgs([selectedDirectory!]));
          selectedDirectory = null;
        }
      } else {
        Get.back();
        Snackbar.show(I18nKey.labelSaveCancel.tr);
      }
    }, I18nKey.labelExporting.tr);

    if (selectedDirectory != null) {
      MsgBox.yes(I18nKey.labelFileSaved.tr, selectedDirectory!);
    }
  }

  void allImport() async {
    MsgBox.yesOrNo(
      title: I18nKey.labelTips.tr,
      desc: I18nKey.labelImportMojo.tr,
      yes: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
        if (result == null || result.files.single.path == null) return;
        _doAllImport(result.files.single.path!);
      },
    );
  }

  void _doAllImport(String zipFilePath) async {
    await showOverlay(() async {
      var rootPath = await DocPath.getContentPath();
      var dbDir = await sqflite.getDatabasesPath();
      var dbPath = dbDir.joinPath(Db.fileName);

      String timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '').substring(0, 15);
      try {
        await File(dbPath).copy('$dbPath.bak_$timestamp');
      } catch (_) {}

      String tmpDir = rootPath.joinPath('_import_tmp');
      if (await Directory(tmpDir).exists()) await Directory(tmpDir).delete(recursive: true);
      await Zip.uncompress(File(zipFilePath), tmpDir);

      File dbFile = File(tmpDir.joinPath(Db.fileName));
      if (!await dbFile.exists()) {
        Get.back();
        Snackbar.show(I18nKey.labelDataAnomaly.trArgs([Db.fileName]));
        return;
      }

      await Db().db.close();
      await File(dbPath).delete();
      await dbFile.copy(dbPath);
      await Db().init();

      final rawDb = Db().db.database;
      List<Map<String, dynamic>> bookRows;
      try {
        bookRows = await rawDb.rawQuery('SELECT * FROM Book');
      } catch (e) {
        bookRows = [];
      }

      final zipNameToBook = {for (var row in bookRows) '${row['classroomId']}_${row['id']}.zip': row};
      final bookZips = (await Directory(tmpDir).list().toList()).whereType<File>().where((f) => f.path.endsWith('.zip')).toList();

      for (var bookZipFile in bookZips) {
        final bookRow = zipNameToBook[FileUtil.toFileName(bookZipFile.path)];
        if (bookRow == null) continue;

        int classroomId = bookRow['classroomId'] as int;
        int bookId = bookRow['id'] as int;
        String bookTmpDir = tmpDir.joinPath('_book_${classroomId}_$bookId');
        await Zip.uncompress(bookZipFile, bookTmpDir);

        String bookDir = rootPath.joinPath('$classroomId/$bookId');
        await Directory(bookDir).create(recursive: true);

        await for (var entity in Directory(bookTmpDir).list(recursive: true)) {
          if (entity is File) {
            String relPath = entity.path.substring(bookTmpDir.length + 1);
            if (relPath == DocPath.zipRootFile) continue;
            String destPath = bookDir.joinPath(relPath);
            await Directory(destPath.substring(0, destPath.lastIndexOf('/'))).create(recursive: true);
            await entity.copy(destPath);
          }
        }
      }

      await Directory(tmpDir).delete(recursive: true);
      Get.back();
      Snackbar.show(I18nKey.labelImportSuccess.tr);
    }, I18nKey.labelImporting.tr);
  }

  static void _createZipFileInIsolate(Map<String, dynamic> message) async {
    SendPort sendPort = message['sendPort'];
    try {
      List<DownloadContent> downloads = message['downloads'];
      String zipFilePath = message['zipFilePath'];
      String relativePath = message['relativePath'];
      String rootPath = message['rootPath'];
      String contentUrl = message['contentUrl'];

      var dirPath = rootPath.joinPath(relativePath);
      await Directory(dirPath).create(recursive: true);

      var rootFilePath = dirPath.joinPath(DocPath.zipRootFile);
      await File(rootFilePath).writeAsString(jsonEncode(ZipRootDoc(contentUrl)));

      List<ZipArchive> zipFiles = [ZipArchive(path: FileUtil.toFileName(rootFilePath), file: File(rootFilePath))];
      for (var download in downloads) {
        final mediaFile = File(dirPath.joinPath(download.path));
        if (await mediaFile.exists()) {
          zipFiles.add(ZipArchive(path: download.path, file: mediaFile));
        }
      }

      await Zip.compress(zipFiles, File(dirPath.joinPath(zipFilePath)));
      sendPort.send({'success': true});
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }
  }

  void databaseImport(BuildContext context, String url, String? mojo) async {
    state.importUrl = url;
    await Db().db.kvDao.insertOrReplace(Kv(K.importUrl, url));
    if (I18nKey.labelImportMojo.tr != mojo) {
      Get.back();
      Snackbar.show(I18nKey.labelImportCanceled.tr);
      return;
    }
    showOverlay(() async {
      var path = await sqflite.getDatabasesPath();
      try {
        final dbPath = path.joinPath(Db.fileName);
        final dbFile = File(dbPath);
        String timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '').substring(0, 15);
        if (await dbFile.exists()) await dbFile.copy('$dbPath.bak_$timestamp');
      } catch (_) {}
      var downloadDocResult = await DownloadDoc.start(url, path.joinPath(Db.fileName));
      await Db().db.close();
      await Db().init();
      await Db().db.kvDao.insertOrReplace(Kv(K.importUrl, url));
      Get.back();
      Snackbar.show(downloadDocResult == DownloadDocResult.success ? I18nKey.labelImportSuccess.tr : I18nKey.labelImportFailed.tr);
    }, I18nKey.labelImporting.tr);
  }
}
