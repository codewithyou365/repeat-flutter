import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'gs_cr_stats_learn_state.dart';

class GsCrStatsLearnLogic extends GetxController {
  static const String id = "MainStatsLearnStateList";
  final GsCrStatsLearnState state = GsCrStatsLearnState();

  @override
  onInit() async {
    super.onInit();
    state.progress = await Db().db.scheduleDao.getAllVerseOverallPrg(Classroom.curr);
    update([id]);
  }
}
