import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/model/learn_segment.dart';
import 'package:repeat_flutter/page/main_repeat/main_repeat_logic.dart';

import 'main_repeat_finish_state.dart';

class MainRepeatFinishLogic extends GetxController {
  final MainRepeatFinishState state = MainRepeatFinishState();

  @override
  void onInit() async {
    super.onInit();
    var curr = await Db().db.scheduleDao.clearCurrent();
    for (var e in curr) {
      var learnSegment = await LearnSegments.from(e.key);
      state.learnSegments.add(learnSegment!);
    }
    await Get.find<MainRepeatLogic>().init();
  }
}
