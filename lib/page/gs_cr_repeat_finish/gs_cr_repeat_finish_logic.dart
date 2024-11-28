import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/gs_cr_repeat_logic.dart';

import 'gs_cr_repeat_finish_state.dart';

class GsCrRepeatFinishLogic extends GetxController {
  static const String id = "GsCrRepeatFinishLogic";
  final GsCrRepeatFinishState state = GsCrRepeatFinishState();

  @override
  void onInit() async {
    super.onInit();
    List<int> curr = [];

    var all = Get.find<GsCrRepeatLogic>().todayProgresses;
    for (SegmentTodayPrg segment in all) {
      curr.add(segment.segmentKeyId);
    }
    for (var segmentKeyId in curr) {
      var learnSegment = await RepeatDocHelp.from(segmentKeyId);
      state.segments.add(learnSegment!);
    }
    update([GsCrRepeatFinishLogic.id]);
  }

}
