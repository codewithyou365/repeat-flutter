import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class InputScheduleConfig {
  List<int> learnIntervalDays;
  int maxRepeatTime;
  List<LearnConfig> learnConfigs;
  List<ReviewLearnConfig> reviewLearnConfigs;

  InputScheduleConfig(
    this.learnIntervalDays,
    this.maxRepeatTime,
    this.learnConfigs,
    this.reviewLearnConfigs,
  );

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> elConfigsJson = learnConfigs.map((elConfig) => elConfig.toJson()).toList();
    List<Map<String, dynamic>> relConfigsJson = reviewLearnConfigs.map((relConfig) => relConfig.toJson()).toList();

    return {
      'learnIntervalDays': learnIntervalDays,
      'maxRepeatTime': maxRepeatTime,
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
      // 手写的旧 JSON 可能没这个键,兜底到默认值,别让整份配置解析失败。
      json['maxRepeatTime'] as int? ?? ScheduleDao.defaultScheduleConfig.maxRepeatTime,
      elConfigsList,
      relConfigsList,
    );
  }
}

void learningSettings() async {
  Select.showSheetWithoutAutoHide(
    title: I18nKey.learningSettings.tr,
    keys: [
      I18nKey.labelConfigSettingsForEl.tr,
      I18nKey.labelConfigSettingsForRel.tr,
      I18nKey.labelMaxRepeatTime.tr,
      I18nKey.labelDetailConfig.tr,
    ],
    callback: (index) {
      if (index == 0) {
        Nav.scCrSettingsEl.push();
      } else if (index == 1) {
        Nav.scCrSettingsRel.push();
      } else if (index == 2) {
        openMaxRepeatTime();
      } else {
        openConfig();
      }
    },
  );
}

/// 答错会把今日进度打回 0,之后要连续答对 maxRepeatTime 次这一节才算完成;
/// 第一遍就答对的走 familiar 分支直接过,不受这个数影响。
void openMaxRepeatTime() {
  final value = RxInt(ScheduleDao.scheduleConfig.maxRepeatTime);
  MsgBox.strInputWithYesOrNo(
    value,
    I18nKey.labelMaxRepeatTime.tr,
    I18nKey.labelMaxRepeatTimeDesc.tr,
    yes: () async {
      if (value.value < 1) {
        // 不关弹窗,让用户重填。
        Snackbar.show(I18nKey.labelMaxRepeatTimeInvalid.tr);
        return;
      }
      ScheduleDao.scheduleConfig.maxRepeatTime = value.value;
      String config = json.encode(ScheduleDao.scheduleConfig);
      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.todayScheduleConfig, config));
      Get.back();
      Snackbar.show(I18nKey.labelSaved.tr);
    },
  );
}

void openConfig() {
  showOverlay(() async {
    var configJsonStr = const JsonEncoder.withIndent(' ').convert(
      InputScheduleConfig(
        ScheduleDao.scheduleConfig.learnIntervalDays,
        ScheduleDao.scheduleConfig.maxRepeatTime,
        ScheduleDao.scheduleConfig.learnConfigs,
        ScheduleDao.scheduleConfig.reviewLearnConfigs,
      ),
    );
    Nav.editor.push(
      arguments: EditorArgs(
        title: I18nKey.labelDetailConfig.tr,
        value: configJsonStr,
        save: (str) async {
          showTransparentOverlay(() async {
            Map<String, dynamic> configJson = json.decode(str);
            InputScheduleConfig inputConfig = InputScheduleConfig.fromJson(configJson);
            ScheduleConfig config = ScheduleConfig(
              learnIntervalDays: inputConfig.learnIntervalDays,
              maxRepeatTime: inputConfig.maxRepeatTime,
              learnConfigs: inputConfig.learnConfigs,
              reviewLearnConfigs: inputConfig.reviewLearnConfigs,
            );
            ScheduleDao.scheduleConfig = config;
            String value = json.encode(ScheduleDao.scheduleConfig);
            Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.todayScheduleConfig, value));
            Get.back();
            Snackbar.show(I18nKey.labelSaved.tr);
          });
        },
      ),
    );
  }, I18nKey.loading.tr);
}
