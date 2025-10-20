import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';

import 'widgets/calendar.dart';
import 'widgets/progress.dart';
import 'widgets/summary.dart';
import 'sc_cr_stats_state.dart';

class ScCrStatsLogic extends GetxController {
  static const String id = "GsCrStatsLogic";
  final ScCrStatsState state = ScCrStatsState();
  late ProgressLogic progressLogic = ProgressLogic();
  late SummaryLogic summaryLogic = SummaryLogic();
  late CalendarLogic calendarLogic = CalendarLogic<ScCrStatsLogic>(this);

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  init() async {
    await progressLogic.init();
    var all = await Db().db.statsDao.collectAll();
    summaryLogic.init(all[0], all[1], (all[2] / 60000.0).toInt(), (all[3] / 60000.0).toInt());
    calendarLogic.init();
    update([ScCrStatsLogic.id]);
  }
}
