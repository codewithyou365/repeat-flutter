import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/logic/model/kv.dart';

enum MainRepeatStep { recall, evaluate, finish }

class MainRepeatState {
  var total = 10;
  Map<int, Kv> indexIdToKv = {};
  var progress = (-1).obs;
  var lessonFilePath = "".obs;
  var segmentKey = "".obs;
  var segmentValue = "".obs;

  var step = MainRepeatStep.recall;
  var learnContent = LearnContent([], []);

  MainRepeatState() {
    ///Initialize variables
  }
}
