import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_settings_state.dart';

class InputScheduleConfig {
  List<int> learnIntervalDays;
  List<LearnConfig> learnConfigs;
  List<ReviewLearnConfig> reviewLearnConfigs;

  InputScheduleConfig(
    this.learnIntervalDays,
    this.learnConfigs,
    this.reviewLearnConfigs,
  );

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> elConfigsJson = learnConfigs.map((elConfig) => elConfig.toJson()).toList();
    List<Map<String, dynamic>> relConfigsJson = reviewLearnConfigs.map((relConfig) => relConfig.toJson()).toList();

    return {
      'learnIntervalDays': learnIntervalDays,
      'learnConfigs': elConfigsJson,
      'reviewLearnConfigs': relConfigsJson,
    };
  }

  factory InputScheduleConfig.fromJson(Map<String, dynamic> json) {
    var learnIntervalDays = (json['learnIntervalDays'] as List).map((e) => e as int).toList();
    var elConfigsList = (json['learnConfigs'] as List).map((e) => LearnConfig.fromJson(e as Map<String, dynamic>)).toList();
    var relConfigsList = (json['reviewLearnConfigs'] as List).map((e) => ReviewLearnConfig.fromJson(e as Map<String, dynamic>)).toList();

    return InputScheduleConfig(
      learnIntervalDays,
      elConfigsList,
      relConfigsList,
    );
  }
}

class GsCrSettingsLogic extends GetxController {
  final GsCrSettingsState state = GsCrSettingsState();

  void openConfig() {
    state.configJson = const JsonEncoder.withIndent(' ').convert(
      InputScheduleConfig(
        ScheduleDao.scheduleConfig.learnIntervalDays,
        ScheduleDao.scheduleConfig.learnConfigs,
        ScheduleDao.scheduleConfig.reviewLearnConfigs,
      ),
    );
    Nav.editor.push(
      arguments: EditorArgs(
        title: I18nKey.labelDetailConfig.tr,
        value: state.configJson,
        save: (str) async {
          state.configJson = str;
          inputConfig();
        },
      ),
    );
  }

  void inputConfig() {
    showTransparentOverlay(() async {
      Map<String, dynamic> configJson = json.decode(state.configJson);
      InputScheduleConfig inputConfig = InputScheduleConfig.fromJson(configJson);
      ScheduleConfig config = ScheduleConfig(
        learnIntervalDays: inputConfig.learnIntervalDays,
        resetIntervalDays: ScheduleDao.defaultScheduleConfig.resetIntervalDays,
        maxRepeatTime: ScheduleDao.defaultScheduleConfig.maxRepeatTime,
        learnConfigs: inputConfig.learnConfigs,
        reviewLearnConfigs: inputConfig.reviewLearnConfigs,
      );
      ScheduleDao.scheduleConfig = config;
      String value = json.encode(ScheduleDao.scheduleConfig);
      Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.todayScheduleConfig, value));
      Get.back();
      Snackbar.show(I18nKey.labelSaved.tr);
    });
  }
}
