import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment.dart' as entity;
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';

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
    var doc = await downloadDocPath(url);
    if (doc == null) {
      await Db().db.contentIndexDao.deleteContentIndex(ContentIndex(Classroom.curr, url, 0));
      return;
    }
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      await Db().db.contentIndexDao.deleteContentIndex(ContentIndex(Classroom.curr, url, 0));
      return;
    }
    var kv = await RepeatDoc.fromPath(doc.path, uri);
    if (kv == null) {
      await Db().db.contentIndexDao.deleteContentIndex(ContentIndex(Classroom.curr, url, 0));
      return;
    }
    List<entity.Segment> segments = [];
    for (var lessonIndex = 0; lessonIndex < kv.lesson.length; lessonIndex++) {
      var lesson = kv.lesson[lessonIndex];
      for (var segmentIndex = 0; segmentIndex < lesson.segment.length; segmentIndex++) {
        var segment = lesson.segment[segmentIndex];
        var key = "${kv.rootPath}|${lesson.key}|${segment.key}";
        segments.add(entity.Segment(Classroom.curr, key, 0, 0, 0, 0, 0));
      }
    }

    await Db().db.scheduleDao.deleteContent(url, segments);
    Get.find<GsCrLogic>().init();
  }

  add(String url) async {
    var idleSortSequenceNumber = await Db().db.contentIndexDao.getIdleSortSequenceNumber(Classroom.curr);
    if (idleSortSequenceNumber == null) {
      print("too many data");
      return;
    }
    var contentIndex = ContentIndex(Classroom.curr, url, idleSortSequenceNumber);
    state.indexes.add(contentIndex);
    update([GsCrContentLogic.id]);
    await Db().db.contentIndexDao.insertContentIndex(contentIndex);
  }

  Future<int> getUnitCount(String url) async {
    var doc = await downloadDocPath(url);
    if (doc == null) {
      return 0;
    }
    var kv = await RepeatDoc.fromPath(doc.path, Uri.parse(url));
    if (kv == null) {
      print("data error");
      return 0;
    }
    var total = 0;
    for (var d in kv.lesson) {
      total += d.segment.length;
    }
    return total;
  }

  Future<void> addToSchedule(String url, int contentIndexSort) async {
    var doc = await downloadDocPath(url);
    if (doc == null) {
      return;
    }

    List<entity.Segment> segments = [];
    List<SegmentOverallPrg> segmentOverallPrgs = [];
    var kv = await RepeatDoc.fromPath(doc.path, Uri.parse(url));
    if (kv == null) {
      print("data error");
      return;
    }
    if (kv.lesson.length >= 100000) {
      print("too many data");
      return;
    }
    for (var d in kv.lesson) {
      if (d.segment.length >= 100000) {
        print("too many data");
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
        segments.add(entity.Segment(
          Classroom.curr,
          key,
          doc.id!,
          mediaDocId,
          lessonIndex,
          segmentIndex,
          contentIndexSort * 10000000000 + lessonIndex * 100000 + segmentIndex,
        ));
        segmentOverallPrgs.add(SegmentOverallPrg(Classroom.curr, key, Date.from(now), 0));
      }
    }
    await Db().db.scheduleDao.importSegment(segments, segmentOverallPrgs);
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
      (fl) async {
        kv = await RepeatDoc.fromPath(fl.path, Uri.parse(url));
        if (kv == null) {
          return null;
        }
        rootPath = fl.folderPath.joinPath(kv!.rootPath);
        return DocLocation(rootPath, urlToDocName(url));
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
          (fl) async => DocLocation.create(rootPath.joinPath(v.path)),
          progressCallback: downloadProgress,
        );
      }
    }
    SegmentHelp.clear();
  }
}
