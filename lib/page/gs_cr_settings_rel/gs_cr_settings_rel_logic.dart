import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

import 'gs_cr_settings_rel_state.dart';

class GsCrSettingsRelLogic extends GetxController {
  static const String elConfigsId = "elConfigsId";
  final GsCrSettingsRelState state = GsCrSettingsRelState();
  static int valueKey = 0;

  @override
  Future<void> onInit() async {
    super.onInit();

    for (var index = 0; index < ScheduleDao.scheduleConfig.relConfigs.length; index++) {
      var value = ScheduleDao.scheduleConfig.relConfigs[index];
      state.relConfigs.add(RelConfigView(
          index,
          ValueKey(valueKey++),
          RelConfig(
            value.level,
            value.before,
            value.from,
            value.learnCountPerGroup,
          )));
    }
  }

  void setCurrElConfig(RelConfigView configView) {
    var index = configView.index;
    var config = configView.config;
    state.currRelConfigIndex = index;
    state.currRelConfig.level.value = config.level;
    state.currRelConfig.before.value = config.before;
    state.currRelConfig.from.value = config.from.value;
    state.currRelConfig.learnCountPerGroup.value = config.learnCountPerGroup;
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = state.relConfigs.removeAt(oldIndex);
    state.relConfigs.insert(newIndex, item);
    updateIndexAndView();
  }

  void copyItem() {
    var config = RelConfig(
      state.currRelConfig.level.value,
      state.currRelConfig.before.value,
      Date(state.currRelConfig.from.value),
      state.currRelConfig.learnCountPerGroup.value,
    );
    state.relConfigs.add(RelConfigView(0, ValueKey(valueKey++), config));
    updateIndexAndView();
  }

  void deleteItem() {
    int index = state.currRelConfigIndex;
    state.relConfigs.removeAt(index);
    updateIndexAndView();
  }

  void updateItem() {
    int index = state.currRelConfigIndex;
    var config = state.relConfigs[index];
    config.config.level = state.currRelConfig.level.value;
    config.config.before = state.currRelConfig.before.value;
    config.config.from = Date(state.currRelConfig.from.value);
    config.config.learnCountPerGroup = state.currRelConfig.learnCountPerGroup.value;
    updateIndexAndView();
  }

  void updateIndexAndView() {
    for (var index = 0; index < state.relConfigs.length; index++) {
      state.relConfigs[index].index = index;
      state.relConfigs[index].config.level = index;
    }
    update([elConfigsId]);
  }

  bool isSame() {
    List<RelConfig> a = ScheduleDao.scheduleConfig.relConfigs;
    List<RelConfig> b = [];
    for (var index = 0; index < state.relConfigs.length; index++) {
      b.add(state.relConfigs[index].config);
    }
    String aStr = json.encode(a);
    String bStr = json.encode(b);
    return aStr == bStr;
  }

  void save() {
    List<RelConfig> newElConfigs = [];
    for (var index = 0; index < state.relConfigs.length; index++) {
      newElConfigs.add(state.relConfigs[index].config);
    }
    ScheduleDao.scheduleConfig.relConfigs = newElConfigs;
    String value = json.encode(ScheduleDao.scheduleConfig);
    Db().db.scheduleDao.updateKv(Classroom.curr, CrK.todayLearnScheduleConfig, value);
  }
}
