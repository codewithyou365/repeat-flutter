import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/page/gs_cr_stats/widgets/calendar.dart';
import 'package:repeat_flutter/page/gs_cr_stats/widgets/progress.dart';
import 'package:repeat_flutter/page/gs_cr_stats/widgets/summary.dart';
import 'gs_cr_stats_state.dart';

class GsCrStatsLogic extends GetxController {
  static const String id = "GsCrStatsLogic";
  final GsCrStatsState state = GsCrStatsState();
  late ProgressLogic progressLogic = ProgressLogic();
  late SummaryLogic summaryLogic = SummaryLogic();
  late CalendarLogic calendarLogic = CalendarLogic<GsCrStatsLogic>(this);

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
    update([GsCrStatsLogic.id]);
  }
}
