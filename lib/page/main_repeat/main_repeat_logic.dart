import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/schedule_current.dart';
import 'package:repeat_flutter/logic/model/kv.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

import 'main_repeat_state.dart';

class MainRepeatLogic extends GetxController {
  static const String id = "MainRepeatLogic";
  final MainRepeatState state = MainRepeatState();

  @override
  Future<void> onInit() async {
    super.onInit();
    state.learnContent = await Db().db.scheduleDao.initCurrent();
    state.total = state.learnContent.schedulesCurrent.length;
    setProgress(state.learnContent.schedulesCurrent);
    await setCurrentLearnContent();
    update([MainRepeatLogic.id]);
  }

  void show() {
    state.step = MainRepeatStep.evaluate;
    update([MainRepeatLogic.id]);
  }

  void error({next = false}) async {
    var curr = state.learnContent.schedulesCurrent[state.scheduleIndex];
    await Db().db.scheduleDao.error(curr.key);
    state.step = MainRepeatStep.finish;
    update([MainRepeatLogic.id]);
    if (next) {
      this.next();
    }
  }

  void know() async {
    var curr = state.learnContent.schedulesCurrent[state.scheduleIndex];
    await Db().db.scheduleDao.error(curr.key);
    state.step = MainRepeatStep.finish;
    update([MainRepeatLogic.id]);
    next();
  }

  void next() async {
    state.scheduleIndex = state.scheduleIndex + 1;
    state.step = MainRepeatStep.recall;
    await setCurrentLearnContent();
    update([MainRepeatLogic.id]);
  }

  Future<Kv?> setCurrentLearnContent() async {
    if (state.learnContent.schedulesCurrent.isEmpty) {
      return null;
    }
    var curr = state.learnContent.schedulesCurrent[state.scheduleIndex];
    var segmentIndex = await Db().db.scheduleDao.getSegment(curr.key);
    if (segmentIndex == null) {
      return null;
    }
    var kv = state.indexIdToKv[segmentIndex.indexFileId];
    if (kv == null) {
      kv = await Kv.fromFile(segmentIndex.indexFilePath, Uri.parse(segmentIndex.indexFileUrl));
      state.indexIdToKv[segmentIndex.indexFileId] = kv;
    }
    var lesson = kv.lesson[segmentIndex.lessonIndex];
    var segment = lesson.segment[segmentIndex.segmentIndex];
    state.lessonFilePath = segmentIndex.lessonFilePath;
    state.segmentIndex.value = segmentIndex.segmentIndex;
    state.segmentKey.value = segment.key;
    state.segmentValue.value = segment.value;
    for (var s in lesson.segment) {
      state.segments.add(Line.toLine(s.start, s.end));
    }
    return kv;
  }

  setProgress(List<ScheduleCurrent> currents) {
    var finishCount = 0;
    for (var value in currents) {
      if (value.progress >= ScheduleDao.maxRepeatTime) {
        finishCount++;
      }
    }
    state.progress.value = finishCount;
  }
}
