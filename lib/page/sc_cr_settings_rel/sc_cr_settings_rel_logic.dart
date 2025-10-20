import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'sc_cr_settings_rel_state.dart';

class ScCrSettingsRelLogic extends GetxController {
  static const String elConfigsId = "elConfigsId";
  final ScCrSettingsRelState state = ScCrSettingsRelState();
  static int valueKey = 0;

  @override
  Future<void> onInit() async {
    super.onInit();

    for (var index = 0; index < ScheduleDao.scheduleConfig.reviewLearnConfigs.length; index++) {
      var value = ScheduleDao.scheduleConfig.reviewLearnConfigs[index];
      state.reviewLearnConfigs.add(
        RelConfigView(
          index,
          ValueKey(valueKey++),
          ReviewLearnConfig(
            title: value.title,
            level: value.level,
            before: value.before,
            from: value.from,
            learnCountPerGroup: value.learnCountPerGroup,
          ),
        ),
      );
    }
  }

  void setCurrElConfig(RelConfigView configView) {
    var index = configView.index;
    var config = configView.config;
    state.currRelConfigIndex = index;
    state.currRelConfig.title.value = config.title;
    state.currRelConfig.level.value = config.level;
    state.currRelConfig.before.value = config.before;
    state.currRelConfig.from.value = config.from.value;
    state.currRelConfig.learnCountPerGroup.value = config.learnCountPerGroup;
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = state.reviewLearnConfigs.removeAt(oldIndex);
    state.reviewLearnConfigs.insert(newIndex, item);
    updateIndexAndView();
  }

  void reset() {
    MsgBox.yesOrNo(
      title: I18nKey.labelTips.tr,
      desc: I18nKey.labelResetConfig.tr,
      yes: () {
        valueKey = 0;
        state.reviewLearnConfigs = [];
        for (var index = 0; index < ScheduleDao.defaultScheduleConfig.reviewLearnConfigs.length; index++) {
          var value = ScheduleDao.defaultScheduleConfig.reviewLearnConfigs[index];
          state.reviewLearnConfigs.add(
            RelConfigView(
              index,
              ValueKey(valueKey++),
              ReviewLearnConfig(
                title: value.title,
                level: value.level,
                before: value.before,
                from: value.from,
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

  void addItem() {
    var config = ReviewLearnConfig(
      title: "LR",
      level: 0,
      before: 4,
      from: Date(20240321),
      learnCountPerGroup: 0,
    );
    state.reviewLearnConfigs.add(RelConfigView(0, ValueKey(valueKey++), config));
    updateIndexAndView();
  }

  void copyItem() {
    var config = ReviewLearnConfig(
      title: state.currRelConfig.title.value,
      level: state.currRelConfig.level.value,
      before: state.currRelConfig.before.value,
      from: Date(state.currRelConfig.from.value),
      learnCountPerGroup: state.currRelConfig.learnCountPerGroup.value,
    );
    state.reviewLearnConfigs.add(RelConfigView(0, ValueKey(valueKey++), config));
    updateIndexAndView();
    Get.back();
  }

  void deleteItem() {
    int index = state.currRelConfigIndex;
    state.reviewLearnConfigs.removeAt(index);
    updateIndexAndView();
    Get.back();
  }

  void updateItem() {
    int index = state.currRelConfigIndex;
    var config = state.reviewLearnConfigs[index];
    config.config.title = state.currRelConfig.title.value;
    config.config.level = state.currRelConfig.level.value;
    config.config.before = state.currRelConfig.before.value;
    config.config.from = Date(state.currRelConfig.from.value);
    config.config.learnCountPerGroup = state.currRelConfig.learnCountPerGroup.value;
    updateIndexAndView();
    Get.back();
  }

  void updateIndexAndView() {
    for (var index = 0; index < state.reviewLearnConfigs.length; index++) {
      state.reviewLearnConfigs[index].index = index;
      state.reviewLearnConfigs[index].config.level = index;
    }
    update([elConfigsId]);
  }

  bool isSame() {
    List<ReviewLearnConfig> a = ScheduleDao.scheduleConfig.reviewLearnConfigs;
    List<ReviewLearnConfig> b = [];
    for (var index = 0; index < state.reviewLearnConfigs.length; index++) {
      b.add(state.reviewLearnConfigs[index].config);
    }
    String aStr = json.encode(a);
    String bStr = json.encode(b);
    return aStr == bStr;
  }

  void save() {
    List<ReviewLearnConfig> newElConfigs = [];
    for (var index = 0; index < state.reviewLearnConfigs.length; index++) {
      newElConfigs.add(state.reviewLearnConfigs[index].config);
    }
    ScheduleDao.scheduleConfig.reviewLearnConfigs = newElConfigs;
    String value = json.encode(ScheduleDao.scheduleConfig);
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.todayScheduleConfig, value));
  }
}
