import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/logic/schedule_help.dart';
import 'package:repeat_flutter/logic/widget/lesson_list.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/logic/widget/segment_list.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import '../../logic/doc_help.dart' show DocHelp;
import 'gs_cr_content_state.dart';

class GsCrContentLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentState state = GsCrContentState();
  late LessonList lessonList = LessonList<GsCrContentLogic>(this);
  late SegmentList segmentList = SegmentList<GsCrContentLogic>(this);
  static RegExp reg = RegExp(r'^[0-9A-Z]+$');

  @override
  void onInit() {
    super.onInit();
    init();
  }

  init() async {
    state.list.clear();
    state.list.addAll(await Db().db.contentDao.getAllContent(Classroom.curr));
    update([GsCrContentLogic.id]);
  }

  resetDoc(int contentId) async {
    await Db().db.contentDao.updateDocId(contentId, 0);
    await init();
  }

  delete(int contentId, int contentSerial) async {
    showOverlay(() async {
      state.list.removeWhere((element) => identical(element.id, contentId));
      await Db().db.scheduleDao.hideContentAndDeleteSegment(contentId, contentSerial);
      Get.find<GsCrLogic>().init();
      update([GsCrContentLogic.id]);
    }, I18nKey.labelDeleting.tr);
  }

  showLesson(int contentId) async {
    var content = await Db().db.contentDao.getById(contentId);
    if (content == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    lessonList.show(
      initContentNameSelect: content.name,
      removeWarning: () async {
        await init();
      },
    );
  }

  showSegment(int contentId) async {
    var content = await Db().db.contentDao.getById(contentId);
    if (content == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    segmentList.show(
      initContentNameSelect: content.name,
      removeWarning: () async {
        await init();
      },
    );
  }

  addByZip(int contentId, int contentSerial) async {
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
    showOverlay(() async {
      var rootPath = await DocPath.getContentPath();
      var zipTargetPath = rootPath.joinPath(DocPath.getRelativePath(contentSerial));
      await Zip.uncompress(File(path), zipTargetPath);
      ZipRootDoc? zipRoot = await ZipRootDoc.fromPath(zipTargetPath.joinPath(DocPath.zipRootFile));
      if (zipRoot == null) {
        Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['81']));
        return;
      }

      var kv = await DocHelp.fromPath(DocPath.getRelativeIndexPath(contentSerial));
      if (kv == null) {
        Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['88']));
        return;
      }
      var allDownloads = DocHelp.getDownloads(kv);
      // for media document
      for (var i = 0; i < allDownloads.length; i++) {
        var v = allDownloads[i];
        var relativeMediaPath = DocPath.getRelativePath(contentSerial).joinPath(v.path);
        var url = v.url;
        String hash = v.hash;
        await Db().db.docDao.insertDoc(Doc(url, relativeMediaPath, hash));
      }

      // for repeat document
      var indexPath = DocPath.getRelativeIndexPath(contentSerial);
      var targetRepeatDocPath = rootPath.joinPath(indexPath);
      String hash = await Hash.toSha1(targetRepeatDocPath);
      await Db().db.docDao.insertDoc(Doc(zipRoot.url, indexPath, hash));
      var indexJsonDocId = await Db().db.docDao.getIdByPath(indexPath);
      if (indexJsonDocId == null) {
        return;
      }

      await schedule(contentId, indexJsonDocId, zipRoot.url);
    }, I18nKey.labelImporting.tr);
  }

  add(String name) async {
    if (name.isEmpty) {
      Get.back();
      Snackbar.show(I18nKey.labelContentNameEmpty.tr);
      return;
    }
    if (name.length > 3 || !reg.hasMatch(name)) {
      Get.back();
      Snackbar.show(I18nKey.labelContentNameError.tr);
      return;
    }
    if (state.list.any((e) => e.name == name)) {
      Get.back();
      Snackbar.show(I18nKey.labelContentNameDuplicated.tr);
      return;
    }
    await Db().db.contentDao.add(name);
    await init();
    Get.back();
  }

  share(Content model) async {
    showTransparentOverlay(() async {
      var doc = await Db().db.docDao.getById(model.docId);
      if (doc == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
        return;
      }
      var args = <dynamic>[model];
      Nav.gsCrContentShare.push(arguments: args);
    });
  }

  Future<int> getUnitCount(int contentSerial) async {
    RepeatDoc? kv = await DocHelp.fromPath(DocPath.getRelativeIndexPath(contentSerial));
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

  download(int contentId, int contentSerial, String url) async {
    state.indexCount.value = 0;
    state.indexTotal.value = 1;
    var indexPath = DocPath.getRelativeIndexPath(contentSerial);
    var success = await downloadDoc(
      url,
      indexPath,
      progressCallback: downloadProgress,
    );
    if (!success) {
      return;
    }
    RepeatDoc? kv = await DocHelp.fromPath(indexPath);
    if (kv == null) {
      return;
    }
    var rootUrl = url.substring(0, url.lastIndexOf("/"));
    var allDownloads = DocHelp.getDownloads(kv, rootUrl: rootUrl);

    state.indexTotal.value = state.indexTotal.value + kv.lesson.length;
    for (int i = 0; i < allDownloads.length; i++) {
      var v = allDownloads[i];
      await downloadDoc(
        v.url,
        DocPath.getRelativePath(contentSerial).joinPath(v.path),
        hash: v.hash,
        progressCallback: downloadProgress,
      );
    }
    var indexJsonDocId = await Db().db.docDao.getIdByPath(indexPath);
    if (indexJsonDocId == null) {
      return;
    }

    var ok = await schedule(contentId, indexJsonDocId, url);
    if (ok) {
      Nav.back();
    }
  }

  Future<bool> schedule(int contentId, int indexJsonDocId, String url) async {
    var result = await ScheduleHelp.addContentToSchedule(contentId, indexJsonDocId, url);
    if (!result) {
      return false;
    }
    Get.find<GsCrLogic>().init();
    init();
    return true;
  }
}
