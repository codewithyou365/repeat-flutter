import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/schedule_current.dart';
import 'package:repeat_flutter/logic/model/kv.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/main/main_logic.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

import 'main_repeat_state.dart';

class MainRepeatLogic extends GetxController {
  static const String id = "MainRepeatLogic";
  final MainRepeatState state = MainRepeatState();

  @override
  Future<void> onInit() async {
    super.onInit();
    state.learnContent = await Db().db.scheduleDao.initCurrent();
    var total = await Db().db.scheduleDao.totalScheduleCurrent();
    state.total = total!;
    setProgress();
    await setCurrentLearnContent();
    update([MainRepeatLogic.id]);
  }

  @override
  void onClose() {
    super.onClose();
    Get.find<MainLogic>().init();
  }

  void show() {
    state.step = MainRepeatStep.evaluate;
    update([MainRepeatLogic.id]);
  }

  void error({next = false}) async {
    if (state.learnContent.schedulesCurrent.isEmpty) {
      Nav.mainRepeatFinish.push();
      return;
    }
    var curr = state.learnContent.schedulesCurrent[state.scheduleIndex];
    await Db().db.scheduleDao.error(curr);
    state.learnContent.schedulesCurrent.sort(schedulesCurrentSort);
    state.step = MainRepeatStep.finish;
    update([MainRepeatLogic.id]);
    if (next) {
      this.next();
    }
  }

  void know() async {
    if (state.learnContent.schedulesCurrent.isEmpty) {
      Nav.mainRepeatFinish.push();
      return;
    }
    var curr = state.learnContent.schedulesCurrent[state.scheduleIndex];
    await Db().db.scheduleDao.right(curr);
    if (curr.progress >= ScheduleDao.maxRepeatTime) {
      state.learnContent.schedulesCurrent.removeAt(0);
    }
    if (state.learnContent.schedulesCurrent.isEmpty) {
      Nav.mainRepeatFinish.push();
      return;
    }
    state.learnContent.schedulesCurrent.sort(schedulesCurrentSort);
    setProgress();
    state.step = MainRepeatStep.finish;
    next();
  }

  void next() async {
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
    state.segmentDatabaseKey.value = curr.key;
    var lesson = kv.lesson[segmentIndex.lessonIndex];
    var segment = lesson.segment[segmentIndex.segmentIndex];
    state.lessonFilePath = segmentIndex.lessonFilePath;
    state.segmentIndex.value = segmentIndex.segmentIndex;
    state.segmentKey = segment.key;
    state.segmentValue.value = segment.value;
    for (var s in lesson.segment) {
      state.segments.add(Line.toLine(s.start, s.end));
    }
    return kv;
  }

  setProgress() {
    var currents = state.learnContent.schedulesCurrent;
    state.progress.value = state.total - currents.length;
  }

  int schedulesCurrentSort(ScheduleCurrent a, ScheduleCurrent b) {
    if (a.viewTime != b.viewTime) {
      return a.viewTime.compareTo(b.viewTime);
    } else {
      return a.sort.compareTo(b.sort);
    }
  }
}
