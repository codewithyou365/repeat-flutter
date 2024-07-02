import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_settings_dsc_state.dart';

class GsCrSettingsDscLogic extends GetxController {
  final GsCrSettingsState state = GsCrSettingsState();

  void resetDailySchedule() {
    showOverlay(() async {
      await Db().db.scheduleDao.deleteKv(CrKv(Classroom.curr, CrK.todayLearnCreateDate, ""));
      await Db().db.scheduleDao.deleteKv(CrKv(Classroom.curr, CrK.todayLearnScheduleConfig, ""));
      await Get.find<GsCrLogic>().init();
      Nav.back();
      Snackbar.show(I18nKey.labelFinish.tr);
    }, I18nKey.labelExecuting.tr);
  }
}
