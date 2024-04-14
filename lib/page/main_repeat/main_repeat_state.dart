import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/logic/model/kv.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

enum MainRepeatStep { recall, evaluate, finish }

class MainRepeatState {
  var total = 10;
  Map<int, Kv> indexIdToKv = {};
  var progress = (-1).obs;
  var lessonFilePath = "";
  var scheduleIndex = 0.obs;
  var segmentIndex = 0.obs;
  var segmentKey = "".obs;
  var segmentValue = "".obs;
  List<Line> segments = [];
  var step = MainRepeatStep.finish;
  var learnContent = LearnContent([], []);

  MainRepeatState() {
    ///Initialize variables
  }
}
