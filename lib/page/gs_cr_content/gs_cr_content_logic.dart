import 'dart:convert';
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
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/logic/widget/segment_list.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_content_state.dart';

class GsCrContentLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentState state = GsCrContentState();
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

  show(int contentId, int contentSerial) async {
    var content = await Db().db.scheduleDao.getContentBySerial(contentId, contentSerial);
    if (content == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    segmentList.show(initContentNameSelect: content.name);
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

      var kv = await RepeatDoc.fromPath(DocPath.getRelativeIndexPath(contentSerial));
      if (kv == null) {
        Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['88']));
        return;
      }

      // for media document
      for (var lessonIndex = 0; lessonIndex < kv.lesson.length; lessonIndex++) {
        var v = kv.lesson[lessonIndex];
        var mediaFileName = DocPath.getMediaFileName(lessonIndex, v.mediaExtension);
        var relativeMediaPath = DocPath.getRelativeMediaPath(contentSerial, lessonIndex, v.mediaExtension);

        var url = "";
        String hash = "";
        var currDoc = zipRoot.docs.where((e) => e.path.endsWith('/'.joinPath(mediaFileName))).firstOrNull;
        if (currDoc != null) {
          url = currDoc.url;
          hash = currDoc.hash;
        } else {
          url = Download.defaultUrl.joinPath(relativeMediaPath);
          var targetPath = rootPath.joinPath(relativeMediaPath);
          hash = await Hash.toSha1(targetPath);
        }

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
      Map<String, dynamic>? map = await RepeatDoc.toJsonMap(doc.path);
      if (map == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
        return;
      }

      List<dynamic> lessons = List<dynamic>.from(map['lesson']);
      map['lesson'] = lessons;

      var args = <dynamic>[model];
      for (int i = 0; i < lessons.length; i++) {
        Map<String, dynamic> lesson = Map<String, dynamic>.from(lessons[i]);
        lessons[i] = lesson;
        String url = lesson['url'];
        if (lesson['mediaExtension'] == null || lesson['mediaExtension'] == '') {
          lesson['mediaExtension'] = url.split('.').last;
        }
        lesson['url'] = '';
      }
      args.add(json.encode(map));
      Nav.gsCrContentShare.push(arguments: args);
    });
  }

  Future<int> getUnitCount(int contentSerial) async {
    var kv = await RepeatDoc.fromPath(DocPath.getRelativeIndexPath(contentSerial));
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
    RepeatDoc? kv = await RepeatDoc.fromPath(indexPath, rootUri: Uri.parse(url));
    if (kv == null) {
      return;
    }

    state.indexTotal.value = state.indexTotal.value + kv.lesson.length;
    for (int i = 0; i < kv.lesson.length; i++) {
      var v = kv.lesson[i];
      var innerUrl = v.url;
      if (innerUrl == "") {
        innerUrl = kv.rootUrl.joinPath(DocPath.getMediaFileName(i, v.mediaExtension));
      } else if (!innerUrl.startsWith("http")) {
        innerUrl = kv.rootUrl.joinPath(innerUrl);
      }
      await downloadDoc(
        innerUrl,
        DocPath.getRelativeMediaPath(contentSerial, i, v.mediaExtension),
        hash: v.hash,
        progressCallback: downloadProgress,
      );
    }
    var indexJsonDocId = await Db().db.docDao.getIdByPath(indexPath);
    if (indexJsonDocId == null) {
      return;
    }

    await schedule(contentId, indexJsonDocId, url);

    Nav.back();
  }

  Future<bool> schedule(int contentId, int indexJsonDocId, String url) async {
    var result = await ScheduleHelp.addContentToSchedule(contentId, indexJsonDocId, url);
    if (!result) {
      return false;
    }
    Get.find<GsCrLogic>().init();
    init();
    RepeatDocHelp.clear();
    return true;
  }
}
