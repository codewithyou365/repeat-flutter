import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/db/entity/segment_key.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment.dart' as entity;
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_content_state.dart';

class GsCrContentLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentState state = GsCrContentState();

  @override
  void onInit() {
    super.onInit();
    init();
  }

  init() async {
    state.indexes.clear();
    state.indexes.addAll(await Db().db.contentIndexDao.findContentIndex(Classroom.curr));
    update([GsCrContentLogic.id]);
  }

  delete(String url) async {
    state.indexes.removeWhere((element) => identical(element.url, url));
    update([GsCrContentLogic.id]);
    var doc = await downloadDocInfo(url);
    if (doc == null) {
      await Db().db.contentIndexDao.deleteContentIndex(ContentIndex(Classroom.curr, url, 0));
      return;
    }
    // TODO 删除 所有 学习记录
    await Db().db.scheduleDao.deleteContent(url, doc.id!);
    Get.find<GsCrLogic>().init();
  }

  addByZip() async {
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
    var kv = await RepeatDoc.fromPath(repeatDocPath, Uri.parse(zipIndex.url));
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
    rootPath = rootPath.joinPath(kv.rootPath);
    await Folder.ensureExists(rootPath);
    var targetRepeatDocPath = rootPath.joinPath(zipIndex.file);
    await File(repeatDocPath).rename(targetRepeatDocPath);
    String hash = await Hash.toSha1(targetRepeatDocPath);
    await Db().db.docDao.insertDoc(Doc(zipIndex.url, targetRepeatDocPath, hash));

    // for media document
    for (var v in kv.lesson) {
      var targetPath = rootPath.joinPath(v.path);
      await File(zipTargetPath.joinPath(v.path)).rename(targetPath);
      String hash = await Hash.toSha1(targetPath);
      await Db().db.docDao.insertDoc(Doc(kv.rootUrl.joinPath(v.url), targetPath, hash));
    }
  }

  Future<bool> add(String url) async {
    var idleSortSequenceNumber = await Db().db.contentIndexDao.getIdleSortSequenceNumber(Classroom.curr);
    if (idleSortSequenceNumber == null) {
      Snackbar.show(I18nKey.labelTooMuchData.tr);
      return false;
    }
    if (await Db().db.contentIndexDao.count(Classroom.curr, url) != 0) {
      Snackbar.show(I18nKey.labelDataDuplication.tr);
      return false;
    }
    var contentIndex = ContentIndex(Classroom.curr, url, idleSortSequenceNumber);
    state.indexes.add(contentIndex);
    update([GsCrContentLogic.id]);
    await Db().db.contentIndexDao.insertContentIndex(contentIndex);
    return true;
  }

  share(ContentIndex model) async {
    showTransparentOverlay(() async {
      var doc = await downloadDocInfo(model.url);
      if (doc == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
        return;
      }
      Map<String, dynamic>? map = await RepeatDoc.toJsonMap(doc.path);
      if (map == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
        return;
      }

      var repeatDoc = RepeatDoc.fromJsonAndUri(map, Uri.parse(model.url));
      if (repeatDoc == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
        return;
      }
      List<dynamic> lessons = List<dynamic>.from(map['lesson']);
      map['lesson'] = lessons;

      var args = [model.url, repeatDoc.rootPath.joinPath(Url.toDocName(model.url))];
      for (int i = 0; i < lessons.length; i++) {
        Map<String, dynamic> lesson = Map<String, dynamic>.from(lessons[i]);
        lessons[i] = lesson;
        lesson['url'] = lesson['path'];
      }
      args.add(json.encode(map));
      Nav.gsCrContentShare.push(arguments: args);
    });
  }

  Future<int> getUnitCount(String url) async {
    var doc = await downloadDocInfo(url);
    if (doc == null) {
      return 0;
    }
    var kv = await RepeatDoc.fromPath(doc.path, Uri.parse(url));
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

  Future<void> addToSchedule(String url, int contentIndexSort) async {
    var doc = await downloadDocInfo(url);
    if (doc == null) {
      return;
    }
    List<SegmentKey> segmentKeys = [];
    List<entity.Segment> segments = [];
    List<SegmentOverallPrg> segmentOverallPrgs = [];
    var kv = await RepeatDoc.fromPath(doc.path, Uri.parse(url));
    if (kv == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    if (kv.lesson.length >= 100000) {
      Snackbar.show(I18nKey.labelTooMuchData.tr);
      return;
    }
    for (var d in kv.lesson) {
      if (d.segment.length >= 100000) {
        Snackbar.show(I18nKey.labelTooMuchData.tr);
        return;
      }
    }
    var now = DateTime.now();
    for (var lessonIndex = 0; lessonIndex < kv.lesson.length; lessonIndex++) {
      var lesson = kv.lesson[lessonIndex];
      var mediaDocId = 0;
      if (lesson.url != "") {
        if (!lesson.url.startsWith("http")) {
          lesson.url = kv.rootUrl.joinPath(lesson.url);
        }
        var docId = await Db().db.docDao.getId(lesson.url);
        mediaDocId = docId!;
      }
      for (var segmentIndex = 0; segmentIndex < lesson.segment.length; segmentIndex++) {
        var segment = lesson.segment[segmentIndex];
        var key = "${kv.rootPath}|${lesson.key}|${segment.key}";
        //4611686118427387904-(99999*10000000000+99999*100000+99999)
        segmentKeys.add(SegmentKey(
          Classroom.curr,
          key,
        ));
        segments.add(entity.Segment(
          0,
          doc.id!,
          mediaDocId,
          lessonIndex,
          segmentIndex,
          contentIndexSort * 10000000000 + lessonIndex * 100000 + segmentIndex,
        ));
        segmentOverallPrgs.add(SegmentOverallPrg(0, Date.from(now), 0));
      }
    }
    await Db().db.scheduleDao.importSegment(segmentKeys, segments, segmentOverallPrgs);
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

  download(String url) async {
    state.indexCount.value = 0;
    state.indexTotal.value = 1;
    RepeatDoc? kv;
    late String rootPath;
    var success = await downloadDoc(
      url,
      (fl, tempFile) async {
        kv = await RepeatDoc.fromPath(fl.path, Uri.parse(url));
        if (kv == null) {
          return null;
        }
        if (tempFile) {
          rootPath = fl.folderPath.joinPath(kv!.rootPath);
        } else {
          rootPath = DocLocation.create(fl.path).folderPath;
        }
        return DocLocation(rootPath, Url.toDocName(url));
      },
      progressCallback: downloadProgress,
    );
    if (success && kv != null) {
      state.indexTotal.value = state.indexTotal.value + kv!.lesson.length;
      for (var v in kv!.lesson) {
        var innerUrl = v.url;
        if (innerUrl == "") {
          downloadProgress(0, 0, 0, true);
          continue;
        }
        if (!innerUrl.startsWith("http")) {
          innerUrl = kv!.rootUrl.joinPath(v.url);
        }
        await downloadDoc(
          innerUrl,
          (fl, tempFile) async => DocLocation.create(rootPath.joinPath(v.path)),
          hash: v.hash,
          progressCallback: downloadProgress,
        );
      }
    }
    SegmentHelp.clear();
  }
}
