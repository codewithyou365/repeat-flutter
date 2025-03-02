import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/page/gs_cr_stats/widgets/progress.dart';
import 'gs_cr_stats_state.dart';

class GsCrStatsLogic extends GetxController {
  static const String id = "GsCrStatsLogic";
  final GsCrStatsState state = GsCrStatsState();
  late ProgressLogic progressLogic = ProgressLogic();

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  init() async {
    state.progress = await Db().db.scheduleDao.getAllSegmentOverallPrg(Classroom.curr);
    progressLogic.init(state.progress);
    update([GsCrStatsLogic.id]);
  }
}
