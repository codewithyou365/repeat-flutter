import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

import 'gs_cr_settings_el_state.dart';

class GsCrSettingsElLogic extends GetxController {
  static const String elConfigsId = "elConfigsId";
  final GsCrSettingsState state = GsCrSettingsState();
  static int valueKey = 0;

  @override
  Future<void> onInit() async {
    super.onInit();

    for (var index = 0; index < ScheduleDao.scheduleConfig.elConfigs.length; index++) {
      var value = ScheduleDao.scheduleConfig.elConfigs[index];
      state.elConfigs.add(ElConfigView(
          index,
          ValueKey(valueKey++),
          ElConfig(
            value.random,
            value.extend,
            value.level,
            value.learnCount,
            value.learnCountPerGroup,
          )));
    }
  }

  void setCurrElConfig(ElConfigView configView) {
    var index = configView.index;
    var config = configView.config;
    state.currElConfigIndex = index;
    state.currElConfig.random.value = config.random;
    state.currElConfig.extend.value = config.extend;
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
      state.currElConfig.extend.value,
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
    config.config.extend = state.currElConfig.extend.value;
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

  bool isSame() {
    List<ElConfig> a = ScheduleDao.scheduleConfig.elConfigs;
    List<ElConfig> b = [];
    for (var index = 0; index < state.elConfigs.length; index++) {
      b.add(state.elConfigs[index].config);
    }
    String aStr = json.encode(a);
    String bStr = json.encode(b);
    return aStr == bStr;
  }

  void save() {
    List<ElConfig> newElConfigs = [];
    for (var index = 0; index < state.elConfigs.length; index++) {
      newElConfigs.add(state.elConfigs[index].config);
    }
    ScheduleDao.scheduleConfig.elConfigs = newElConfigs;
    String value = json.encode(ScheduleDao.scheduleConfig);
    Db().db.scheduleDao.updateKv(Classroom.curr, CrK.todayLearnScheduleConfig, value);
  }
}
