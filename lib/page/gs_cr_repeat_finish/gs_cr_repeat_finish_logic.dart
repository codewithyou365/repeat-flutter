import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';

import 'gs_cr_repeat_finish_state.dart';

class GsCrRepeatFinishLogic extends GetxController {
  static const String id = "GsCrRepeatFinishLogic";
  final GsCrRepeatFinishState state = GsCrRepeatFinishState();

  @override
  void onInit() async {
    super.onInit();
    List<String> curr = [];
    if (Get.arguments == "review") {
      curr = await Db().db.scheduleDao.tryClear(false);
    } else {
      curr = await Db().db.scheduleDao.tryClear(true);
    }
    for (var key in curr) {
      var learnSegment = await SegmentHelp.from(key);
      state.segments.add(learnSegment!);
    }
    update([GsCrRepeatFinishLogic.id]);
  }

  @override
  void onClose() {
    super.onClose();
    Get.find<GsCrLogic>().init();
    SegmentHelp.clear();
  }
}
