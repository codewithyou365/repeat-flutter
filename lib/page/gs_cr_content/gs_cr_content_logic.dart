import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/logic/schedule_help.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_content_state.dart';

class GsCrContentLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentState state = GsCrContentState();
  static RegExp reg = RegExp(r'^[0-9A-Z]+$');

  @override
  void onInit() {
    super.onInit();
    init();
  }

  init() async {
    state.list.clear();
    state.list.addAll(await Db().db.materialDao.getAllMaterial(Classroom.curr));
    update([GsCrContentLogic.id]);
  }

  resetDoc(int materialId) async {
    await Db().db.materialDao.updateDocId(materialId, 0);
    await init();
  }

  delete(int materialId, int materialSerial) async {
    state.list.removeWhere((element) => identical(element.id, materialId));
    await Db().db.scheduleDao.hideMaterialAndDeleteSegment(materialId, materialSerial);
    Get.find<GsCrLogic>().init();
    update([GsCrContentLogic.id]);
  }

  todoAddByZip() async {
    //TODO
    return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    var path = "";
    if (result != null && result.files.single.path != null) {
      path = result.files.single.path!;
    } else {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return;
    }
    var zipTargetPath = await DocPath.getZipTargetPath(clearFirst: true);
    await Zip.uncompress(File(path), zipTargetPath);
    ZipIndexDoc? zipIndex = await ZipIndexDoc.fromPath();
    if (zipIndex == null) {
      Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['81']));
      return;
    }

    var repeatDocPath = zipTargetPath.joinPath(zipIndex.file);
    var kv = await RepeatDoc.fromPath(repeatDocPath);
    if (kv == null) {
      Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['88']));
      return;
    }
    var success = await add(zipIndex.url);
    if (!success) {
      return;
    }
    var rootPath = await DocPath.getContentPath();

    // for repeat document
    // rootPath = rootPath.joinPath(kv.rootPath);
    // await Folder.ensureExists(rootPath);
    // var targetRepeatDocPath = rootPath.joinPath(zipIndex.file);
    // await File(repeatDocPath).rename(targetRepeatDocPath);
    // String hash = await Hash.toSha1(targetRepeatDocPath);
    // await Db().db.docDao.insertDoc(Doc(zipIndex.url, targetRepeatDocPath, hash));
    //
    // // for media document
    // for (var v in kv.lesson) {
    //   var targetPath = rootPath.joinPath(v.path);
    //   await File(zipTargetPath.joinPath(v.path)).rename(targetPath);
    //   String hash = await Hash.toSha1(targetPath);
    //   await Db().db.docDao.insertDoc(Doc(kv.rootUrl.joinPath(v.url), targetPath, hash));
    // }
  }

  add(String name) async {
    if (name.isEmpty) {
      Get.back();
      Snackbar.show(I18nKey.labelMaterialNameEmpty.tr);
      return;
    }
    if (name.length > 3 || !reg.hasMatch(name)) {
      Get.back();
      Snackbar.show(I18nKey.labelMaterialNameError.tr);
      return;
    }
    if (state.list.any((e) => e.name == name)) {
      Get.back();
      Snackbar.show(I18nKey.labelMaterialNameDuplicated.tr);
      return;
    }
    await Db().db.materialDao.add(name);
    await init();
    Get.back();
  }

  todoShare(Material model) async {
    // showTransparentOverlay(() async {
    //   var doc = await downloadDocInfo(model.url);
    //   if (doc == null) {
    //     Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
    //     return;
    //   }
    //   Map<String, dynamic>? map = await RepeatDoc.toJsonMap(doc.path);
    //   if (map == null) {
    //     Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
    //     return;
    //   }
    //
    //   var repeatDoc = RepeatDoc.fromJsonAndUri(map, Uri.parse(model.url));
    //   if (repeatDoc == null) {
    //     Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
    //     return;
    //   }
    //   List<dynamic> lessons = List<dynamic>.from(map['lesson']);
    //   map['lesson'] = lessons;
    //
    //   var args = [model.url, Classroom.curr.joinPath(Url.toDocName(model.url))];
    //   for (int i = 0; i < lessons.length; i++) {
    //     Map<String, dynamic> lesson = Map<String, dynamic>.from(lessons[i]);
    //     lessons[i] = lesson;
    //     lesson['url'] = lesson['path'];
    //   }
    //   args.add(json.encode(map));
    //   Nav.gsCrContentShare.push(arguments: args);
    // });
  }

  Future<int> getUnitCount(int materialSerial) async {
    var kv = await RepeatDoc.fromPath(DocPath.getRelativeIndexPath(materialSerial));
    if (kv == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return 0;
    }
    var total = 0;
    for (var d in kv.lesson) {
      total += d.segment.length;
    }
    return total;
  }

  Future<void> addToSchedule(Material material) async {
    var ret = await ScheduleHelp.addMaterialToSchedule(material);
    if (ret == false) {
      return;
    }
    Get.find<GsCrLogic>().init();
  }

  downloadProgress(int startTime, int count, int total, bool finish) {
    if (finish) {
      state.indexCount.value++;
      state.contentProgress.value = 1;
    } else {
      if (total == -1) {
        int elapse = DateTime.now().millisecondsSinceEpoch - startTime;
        int predict = 5 * 60 * 1000;
        double progress = elapse / predict;
        if (progress > 0.9) {
          state.contentProgress.value = 0.9;
        } else {
          state.contentProgress.value = progress;
        }
      } else {
        state.contentProgress.value = count / total;
      }
    }
  }

  download(int materialId, int materialSerial, String url) async {
    state.indexCount.value = 0;
    state.indexTotal.value = 1;
    var indexPath = DocPath.getRelativeIndexPath(materialSerial);
    var success = await downloadDoc(
      url,
      indexPath,
      progressCallback: downloadProgress,
    );
    if (!success) {
      return;
    }
    RepeatDoc? kv = await RepeatDoc.fromPath(indexPath, rootUri: Uri.parse(url));
    if (kv == null) {
      return;
    }

    state.indexTotal.value = state.indexTotal.value + kv.lesson.length;
    for (int i = 0; i < kv.lesson.length; i++) {
      var v = kv.lesson[i];
      var innerUrl = v.url;
      if (innerUrl == "") {
        downloadProgress(0, 0, 0, true);
        continue;
      }
      if (!innerUrl.startsWith("http")) {
        innerUrl = kv.rootUrl.joinPath(v.url);
      }
      await downloadDoc(
        innerUrl,
        DocPath.getRelativeMediaPath(materialSerial, i, v.mediaExtension),
        hash: v.hash,
        progressCallback: downloadProgress,
      );
    }
    var indexJsonDocId = await Db().db.docDao.getIdByPath(indexPath);
    if (indexJsonDocId == null) {
      return;
    }

    await Db().db.materialDao.updateDocId(materialId, indexJsonDocId);
    Nav.back();
    init();
    RepeatDocHelp.clear();
  }
}
