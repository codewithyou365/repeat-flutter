import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment.dart' as entity;
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/qa_repeat_file.dart';
import 'package:repeat_flutter/page/main/main_logic.dart';

import 'main_content_state.dart';

class MainContentLogic extends GetxController {
  static const String id = "MainContentLogicList";
  final MainContentState state = MainContentState();

  init() async {
    state.indexes.clear();
    state.indexes.addAll(await Db().db.contentIndexDao.findContentIndex());
    update([MainContentLogic.id]);
  }

  delete(String url) async {
    state.indexes.removeWhere((element) => identical(element.url, url));
    update([MainContentLogic.id]);
    // TODO here some error
    await Db().db.contentIndexDao.deleteContentIndex(ContentIndex(url, 0));
    var deleteKeyList = await Db().db.scheduleDao.findKeyByUrl(url);
    // TODO await Db().db.scheduleDao.deleteContentIndex(Schedule.create(deleteKeyList));
    Get.find<MainLogic>().init();
  }

  add(String url) async {
    var idleSortSequenceNumber = await Db().db.contentIndexDao.getIdleSortSequenceNumber();
    if (idleSortSequenceNumber == null) {
      print("too many data");
      return;
    }
    var contentIndex = ContentIndex(url, idleSortSequenceNumber);
    state.indexes.add(contentIndex);
    update([MainContentLogic.id]);
    await Db().db.contentIndexDao.insertContentIndex(contentIndex);
  }

  Future<int> getUnitCount(String url) async {
    var cacheFile = await downloadFilePath(url);
    if (cacheFile == null) {
      return 0;
    }
    var kv = await QaRepeatFile.fromFile(cacheFile.path, Uri.parse(url));
    var total = 0;
    for (var d in kv.lesson) {
      total += d.segment.length;
    }
    return total;
  }

  Future<int> addToSchedule(String url, int contentIndexSort) async {
    var cacheFile = await downloadFilePath(url);
    if (cacheFile == null) {
      return 0;
    }
    var kv = await QaRepeatFile.fromFile(cacheFile.path, Uri.parse(url));
    List<entity.Segment> segments = [];
    List<SegmentOverallPrg> segmentOverallPrgs = [];
    if (kv.lesson.length >= 100000) {
      print("too many data");
      return 0;
    }
    for (var d in kv.lesson) {
      if (d.segment.length >= 100000) {
        print("too many data");
        return 0;
      }
    }

    for (var lessonIndex = 0; lessonIndex < kv.lesson.length; lessonIndex++) {
      var lesson = kv.lesson[lessonIndex];
      var mediaFileId = await Db().db.cacheFileDao.getId(lesson.url);
      for (var segmentIndex = 0; segmentIndex < lesson.segment.length; segmentIndex++) {
        var segment = lesson.segment[segmentIndex];
        var key = "${kv.rootPath}|${lesson.key}|${segment.key}";
        //4611686118427387904-(99999*10000000000+99999*100000+99999)
        segments.add(entity.Segment(key, cacheFile.id!, mediaFileId!, lessonIndex, segmentIndex));
        segmentOverallPrgs.add(SegmentOverallPrg(key, DateTime.now(), 0, contentIndexSort * 10000000000 + lessonIndex * 100000 + segmentIndex));
      }
    }
    await Db().db.scheduleDao.insertSegments(segments);
    await Db().db.scheduleDao.insertSegmentOverallPrgs(segmentOverallPrgs);
    Get.find<MainLogic>().init();
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

  download(String url) async {
    state.indexCount.value = 0;
    state.indexTotal.value = 1;
    late QaRepeatFile kv;
    late String rootPath;
    var success = await downloadFile(
      url,
      (fl) async {
        kv = await QaRepeatFile.fromFile(fl.path, Uri.parse(url));
        rootPath = fl.folderPath.joinPath(kv.rootPath);
        return FileLocation(rootPath, urlToFileName(url));
      },
      progressCallback: downloadProgress,
    );
    if (success) {
      state.indexTotal.value = state.indexTotal.value + kv.lesson.length;
      for (var v in kv.lesson) {
        var innerUrl = v.url;
        if (!innerUrl.startsWith("http")) {
          innerUrl = kv.rootUrl.joinPath(v.url);
        }
        await downloadFile(
          innerUrl,
          (fl) async => FileLocation.create(rootPath.joinPath(v.path)),
          progressCallback: downloadProgress,
        );
      }
    }
  }
}
