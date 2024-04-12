import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/schedule_current.dart';
import 'package:repeat_flutter/logic/model/kv.dart';

import 'main_repeat_state.dart';

class MainRepeatLogic extends GetxController {
  final player = AudioPlayer();
  final MainRepeatState state = MainRepeatState();

  Future<void> init() async {
    state.learnContent = await Db().db.scheduleDao.initCurrent();
    state.total = state.learnContent.schedulesCurrent.length;
    setProgress(state.learnContent.schedulesCurrent);
    await setCurrentLearnContent();
  }

  Future<void> play(String path) async {
    player.play(DeviceFileSource(path));
  }

  setCurrentLearnContent() async {
    if (state.learnContent.schedulesCurrent.isEmpty) {
      return;
    }
    var first = state.learnContent.schedulesCurrent[0];
    var segmentIndex = await Db().db.scheduleDao.getSegment(first.key);
    if (segmentIndex == null) {
      return;
    }
    var kv = state.indexIdToKv[segmentIndex.indexFileId];
    if (kv == null) {
      kv = await Kv.fromFile(segmentIndex.indexFilePath, Uri.parse(segmentIndex.indexFileUrl));
      state.indexIdToKv[segmentIndex.indexFileId] = kv;
    }
    var segment = kv.lesson[segmentIndex.lessonIndex].segment[segmentIndex.segmentIndex];

    state.lessonFilePath.value = segmentIndex.lessonFilePath;
    state.segmentKey.value = segment.key;
    state.segmentValue.value = segment.value;
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
