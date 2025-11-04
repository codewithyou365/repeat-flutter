import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/upload.dart';
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

  void export(BuildContext context, String url, String? mojo) async {
    showOverlay(() async {
      state.exportUrl = url;
      await Db().db.kvDao.insertKv(Kv(K.exportUrl, url));
      var path = await sqflite.getDatabasesPath();
      var res = await upload(url, path.joinPath(Db.fileName), Db.fileName);
      Get.back();
      Snackbar.show(res.data.toString());
    }, I18nKey.labelExporting.tr);
  }

  void import(BuildContext context, String url, String? mojo) async {
    state.importUrl = url;
    await Db().db.kvDao.insertKv(Kv(K.importUrl, url));
    String key = I18nKey.labelImportMojo.tr;
    if (key != mojo) {
      Get.back();
      Snackbar.show(I18nKey.labelImportCanceled.tr);
      return;
    }
    showOverlay(() async {
      var path = await sqflite.getDatabasesPath();
      var downloadDocResult = await DownloadDoc.start(
        url,
        path.joinPath(Db.fileName),
      );
      await Db().db.close();
      await Db().init();
      await Db().db.kvDao.insertKv(Kv(K.importUrl, url));
      Get.back();
      Snackbar.show(downloadDocResult == DownloadDocResult.success ? I18nKey.labelImportSuccess.tr : I18nKey.labelImportFailed.tr);
    }, I18nKey.labelImporting.tr);
  }
}
