import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';

import 'gs_cr_settings_dsc_state.dart';

class GsCrSettingsDscLogic extends GetxController {
  static const String elConfigsId = "elConfigsId";
  final GsCrSettingsState state = GsCrSettingsState();

  @override
  Future<void> onInit() async {
    super.onInit();
    for (var index = 0; index < ScheduleDao.scheduleConfig.elConfigs.length; index++) {
      var value = ScheduleDao.scheduleConfig.elConfigs[index];
      state.elConfigs.add(ElConfigView(ValueKey(index), value));
    }
  }

  void resetDailySchedule() {}

  void setCurrElConfig(ElConfig config) {
    state.currElConfig.random.value = config.random;
    state.currElConfig.extendLevel.value = config.extendLevel;
    state.currElConfig.level.value = config.level;
    state.currElConfig.learnCount.value = config.learnCount;
    state.currElConfig.learnCountPerGroup.value = config.learnCountPerGroup;
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = state.elConfigs.removeAt(oldIndex);
    state.elConfigs.insert(newIndex, item);
    update([elConfigsId]);
  }
}
