import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/page/main/main_logic.dart';

import 'main_repeat_finish_state.dart';

class MainRepeatFinishLogic extends GetxController {
  static const String id = "MainRepeatFinishLogic";
  final MainRepeatFinishState state = MainRepeatFinishState();

  @override
  void onInit() async {
    super.onInit();
    var curr = await Db().db.scheduleDao.finishCurrent();
    for (var key in curr) {
      var learnSegment = await SegmentHelp.from(key);
      state.segments.add(learnSegment!);
    }
    update([MainRepeatFinishLogic.id]);
  }

  @override
  void onClose() {
    super.onClose();
    Get.find<MainLogic>().init();
    SegmentHelp.clear();
  }
}
