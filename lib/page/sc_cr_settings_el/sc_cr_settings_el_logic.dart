import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/logic/widget/learn_interval_config.dart';

import 'sc_cr_settings_el_state.dart';

class ScCrSettingsElLogic extends GetxController {
  static const String elConfigsId = "elConfigsId";
  final ScCrSettingsState state = ScCrSettingsState();
  static int valueKey = 0;
  late LearnIntervalConfig learnIntervalConfig = LearnIntervalConfig<ScCrSettingsElLogic>(this);

  @override
  Future<void> onInit() async {
    super.onInit();

    for (var index = 0; index < ScheduleDao.scheduleConfig.learnConfigs.length; index++) {
      var value = ScheduleDao.scheduleConfig.learnConfigs[index];
      state.learnConfigs.add(
        ElConfigView(
          index,
          ValueKey(valueKey++),
          LearnConfig(
            title: value.title,
            random: value.random,
            level: value.level,
            toLevel: value.toLevel,
            learnCount: value.learnCount,
            learnCountPerGroup: value.learnCountPerGroup,
          ),
        ),
      );
    }
  }

  void setCurrElConfig(ElConfigView configView) {
    var index = configView.index;
    var config = configView.config;
    state.currElConfigIndex = index;
    state.currElConfig.title.value = config.title;
    state.currElConfig.random.value = config.random;
    state.currElConfig.level.value = config.level;
    state.currElConfig.toLevel.value = config.toLevel;
    state.currElConfig.learnCount.value = config.learnCount;
    state.currElConfig.learnCountPerGroup.value = config.learnCountPerGroup;
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = state.learnConfigs.removeAt(oldIndex);
    state.learnConfigs.insert(newIndex, item);
    updateIndexAndView();
  }

  void reset() {
    MsgBox.yesOrNo(
      title: I18nKey.labelTips.tr,
      desc: I18nKey.labelResetConfig.tr,
      yes: () {
        valueKey = 0;
        state.learnConfigs = [];
        for (var index = 0; index < ScheduleDao.defaultScheduleConfig.learnConfigs.length; index++) {
          var value = ScheduleDao.defaultScheduleConfig.learnConfigs[index];
          state.learnConfigs.add(
            ElConfigView(
              index,
              ValueKey(valueKey++),
              LearnConfig(
                title: value.title,
                random: value.random,
                level: value.level,
                toLevel: value.toLevel,
                learnCount: value.learnCount,
                learnCountPerGroup: value.learnCountPerGroup,
              ),
            ),
          );
        }
        updateIndexAndView();
        Get.back();
      },
    );
  }

  void showLearnInterval() {
    learnIntervalConfig.showSheet();
  }

  void addItem() {
    var config = LearnConfig(
      title: "LR",
      random: false,
      level: 1,
      toLevel: 1,
      learnCount: 10,
      learnCountPerGroup: 10,
    );
    state.learnConfigs.add(ElConfigView(0, ValueKey(valueKey++), config));
    updateIndexAndView();
  }

  void copyItem() {
    var config = LearnConfig(
      title: state.currElConfig.title.value,
      random: state.currElConfig.random.value,
      level: state.currElConfig.level.value,
      toLevel: state.currElConfig.toLevel.value,
      learnCount: state.currElConfig.learnCount.value,
      learnCountPerGroup: state.currElConfig.learnCountPerGroup.value,
    );
    state.learnConfigs.add(ElConfigView(0, ValueKey(valueKey++), config));
    updateIndexAndView();
    Get.back();
  }

  void deleteItem() {
    int index = state.currElConfigIndex;
    state.learnConfigs.removeAt(index);
    updateIndexAndView();
    Get.back();
  }

  void updateItem() {
    int index = state.currElConfigIndex;
    var config = state.learnConfigs[index];
    config.config.title = state.currElConfig.title.value;
    config.config.random = state.currElConfig.random.value;
    config.config.level = state.currElConfig.level.value;
    config.config.toLevel = state.currElConfig.toLevel.value;
    config.config.learnCount = state.currElConfig.learnCount.value;
    config.config.learnCountPerGroup = state.currElConfig.learnCountPerGroup.value;
    updateIndexAndView();
    Get.back();
  }

  void updateIndexAndView() {
    for (var index = 0; index < state.learnConfigs.length; index++) {
      state.learnConfigs[index].index = index;
    }
    update([elConfigsId]);
  }

  void tryOpenSaveConfirmDialog(ScCrSettingsElLogic logic) {
    var same = logic.isSame();
    if (same) {
      Get.back();
      return;
    }
    MsgBox.yesOrNo(
      title: I18nKey.labelSavingConfirm.tr,
      desc: I18nKey.labelConfigChange.tr,
      no: () {
        Get.back();
        Get.back();
      },
      yes: () {
        logic.save();
        Get.back();
        Get.back();
      },
    );
  }

  bool isSame() {
    List<LearnConfig> a = ScheduleDao.scheduleConfig.learnConfigs;
    List<LearnConfig> b = [];
    for (var index = 0; index < state.learnConfigs.length; index++) {
      b.add(state.learnConfigs[index].config);
    }
    String aStr = json.encode(a);
    String bStr = json.encode(b);
    return aStr == bStr;
  }

  void save() {
    List<LearnConfig> newElConfigs = [];
    for (var index = 0; index < state.learnConfigs.length; index++) {
      newElConfigs.add(state.learnConfigs[index].config);
    }
    ScheduleDao.scheduleConfig.learnConfigs = newElConfigs;
    String value = json.encode(ScheduleDao.scheduleConfig);
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.todayScheduleConfig, value));
  }
}
