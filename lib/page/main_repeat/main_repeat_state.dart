import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/logic/model/kv.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

enum MainRepeatStep { recall, evaluate, finish }

// recall by value
// recall by media (audio, video or image)
// recall by key

enum MainRepeatMode { byValue, byMedia, byKey }

class MainRepeatState {
  var total = 10;
  Map<int, Kv> indexIdToKv = {};
  var progress = (-1).obs;
  var lessonFilePath = "";
  var scheduleIndex = 0;
  var segmentIndex = 0.obs;

  var segmentDatabaseKey = "".obs;
  var segmentKey = "";
  var segmentValue = "".obs;
  List<Line> segments = [];
  var step = MainRepeatStep.recall;
  var mode = MainRepeatMode.byValue;
  var learnContent = LearnContent([], []);

  MainRepeatState() {
    ///Initialize variables
  }
}
