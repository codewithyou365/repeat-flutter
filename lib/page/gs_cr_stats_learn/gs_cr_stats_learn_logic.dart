import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'gs_cr_stats_learn_state.dart';

class GsCrStatsLearnLogic extends GetxController {
  static const String id = "MainStatsLearnStateList";
  final GsCrStatsLearnState state = GsCrStatsLearnState();

  @override
  onInit() async {
    super.onInit();
    state.progress = await Db().db.scheduleDao.getAllSegmentOverallPrg();
    update([id]);
  }
}
