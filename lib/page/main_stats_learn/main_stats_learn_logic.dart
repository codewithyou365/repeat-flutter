import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/page/main_stats_learn/main_stats_learn_state.dart';

class MainStatsLearnLogic extends GetxController {
  static const String id = "MainStatsLearnStateList";
  final MainStatsLearnState state = MainStatsLearnState();

  @override
  onInit() async {
    super.onInit();
    state.progress = await Db().db.scheduleDao.getAllSegmentOverallPrg();
    update([id]);
  }
}
