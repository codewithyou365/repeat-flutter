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
  List<ElConfig> elConfigs;
  List<RelConfig> relConfigs;

  InputScheduleConfig(
    this.elConfigs,
    this.relConfigs,
  );

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> elConfigsJson = elConfigs.map((elConfig) => elConfig.toJson()).toList();
    List<Map<String, dynamic>> relConfigsJson = relConfigs.map((relConfig) => relConfig.toJson()).toList();

    return {
      'elConfigs': elConfigsJson,
      'relConfigs': relConfigsJson,
    };
  }

  factory InputScheduleConfig.fromJson(Map<String, dynamic> json) {
    var elConfigsList = json['elConfigs'] as List;
    var relConfigsList = json['relConfigs'] as List;

    return InputScheduleConfig(
      elConfigsList.map((e) => ElConfig.fromJson(e as Map<String, dynamic>)).toList(),
      relConfigsList.map((e) => RelConfig.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class GsCrSettingsLogic extends GetxController {
  final GsCrSettingsState state = GsCrSettingsState();

  void openConfig() {
    state.configJson = const JsonEncoder.withIndent(' ').convert(
      InputScheduleConfig(
        ScheduleDao.scheduleConfig.elConfigs,
        ScheduleDao.scheduleConfig.relConfigs,
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
        ScheduleDao.defaultScheduleConfig.forgettingCurve,
        ScheduleDao.defaultScheduleConfig.intervalSeconds,
        ScheduleDao.defaultScheduleConfig.maxRepeatTime,
        inputConfig.elConfigs,
        inputConfig.relConfigs,
      );
      ScheduleDao.scheduleConfig = config;
      String value = json.encode(ScheduleDao.scheduleConfig);
      Db().db.scheduleDao.updateKv(Classroom.curr, CrK.todayScheduleConfig, value);
      Get.back();
      Snackbar.show(I18nKey.labelSaved.tr);
    });
  }
}
