import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';

import 'gs_cr_settings_dsc_state.dart';

class GsCrSettingsDscLogic extends GetxController {
  static const String elConfigsId = "elConfigsId";
  final GsCrSettingsState state = GsCrSettingsState();
  static int valueKey = 0;

  @override
  Future<void> onInit() async {
    super.onInit();

    for (var index = 0; index < ScheduleDao.scheduleConfig.elConfigs.length; index++) {
      var value = ScheduleDao.scheduleConfig.elConfigs[index];
      state.elConfigs.add(ElConfigView(index, ValueKey(valueKey++), value));
    }
  }

  void setCurrElConfig(ElConfigView configView) {
    var index = configView.index;
    var config = configView.config;
    state.currElConfigIndex = index;
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
    updateIndexAndView();
  }

  void copyItem() {
    var config = ElConfig(
      state.currElConfig.random.value,
      state.currElConfig.extendLevel.value,
      state.currElConfig.level.value,
      state.currElConfig.learnCount.value,
      state.currElConfig.learnCountPerGroup.value,
    );
    state.elConfigs.add(ElConfigView(0, ValueKey(valueKey++), config));
    updateIndexAndView();
  }

  void deleteItem() {
    int index = state.currElConfigIndex;
    state.elConfigs.removeAt(index);
    updateIndexAndView();
  }

  void updateItem() {
    int index = state.currElConfigIndex;
    var config = state.elConfigs[index];
    config.config.random = state.currElConfig.random.value;
    config.config.extendLevel = state.currElConfig.extendLevel.value;
    config.config.level = state.currElConfig.level.value;
    config.config.learnCount = state.currElConfig.learnCount.value;
    config.config.learnCountPerGroup = state.currElConfig.learnCountPerGroup.value;
    updateIndexAndView();
  }

  void updateIndexAndView() {
    for (var index = 0; index < state.elConfigs.length; index++) {
      state.elConfigs[index].index = index;
    }
    update([elConfigsId]);
  }
}
