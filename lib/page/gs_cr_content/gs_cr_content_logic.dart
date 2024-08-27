import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/segment_key.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment.dart' as entity;
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
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

  addByScan() async {
    var url = await Nav.gsCrContentScan.push();
    if (url != null && url is String && url != "") {
      await add(url);
    }
  }

  add(String url) async {
    var idleSortSequenceNumber = await Db().db.contentIndexDao.getIdleSortSequenceNumber(Classroom.curr);
    if (idleSortSequenceNumber == null) {
      Snackbar.show(I18nKey.labelTooMuchData.tr);
      return;
    }
    if (await Db().db.contentIndexDao.count(Classroom.curr, url) != 0) {
      Snackbar.show(I18nKey.labelDataDuplication.tr);
      return;
    }
    var contentIndex = ContentIndex(Classroom.curr, url, idleSortSequenceNumber);
    state.indexes.add(contentIndex);
    update([GsCrContentLogic.id]);
    await Db().db.contentIndexDao.insertContentIndex(contentIndex);
  }

  share(ContentIndex model) async {
    showTransparentOverlay(() async {
      var doc = await downloadDocInfo(model.url);
      if (doc == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
        return;
      }
      var kv = await RepeatDoc.fromPath(doc.path, Uri.parse(model.url));
      if (kv == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
        return;
      }
      var illegalLesson = kv.lesson.where((l) => l.path != l.url).toList();
      var args = [model.url, kv.rootPath.joinPath(Url.toDocName(model.url))];
      if (illegalLesson.isNotEmpty) {
        for (Lesson l in kv.lesson) {
          l.url = l.path;
        }
        args.add(json.encode(kv));
      }
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
