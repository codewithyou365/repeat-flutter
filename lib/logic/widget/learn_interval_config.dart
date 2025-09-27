import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class LearnIntervalConfig<T extends GetxController> {
  static const String bodyId = "LearnIntervalConfig.bodyId";
  final T parentLogic;

  List<RxInt> intervals = [];

  LearnIntervalConfig(this.parentLogic);

  Future<void> showSheet() async {
    intervals.clear();
    ScheduleConfig config = ScheduleDao.scheduleConfig;
    for (int i = 1; i < config.learnIntervalDays.length; i++) {
      intervals.add(RxInt(config.learnIntervalDays[i]));
    }
    return Sheet.withHeaderAndBody(
      Get.context!,
      Padding(
        key: GlobalKey(),
        padding: EdgeInsets.symmetric(horizontal: 10.0.w),
        child: Column(
          children: [
            RowWidget.buildButtons([
              Button(I18nKey.btnSave.tr, save),
            ]),
            RowWidget.buildDivider(),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.w),
        child: GetBuilder<T>(
          id: bodyId,
          builder: (context) {
            return ListView(
              shrinkWrap: true,
              children: List.generate(
                intervals.length,
                (index) => Obx(() {
                  final days = '${intervals[index].value} ${intervals[index].value == 1 ? I18nKey.day.tr : I18nKey.days.tr}';
                  return RowWidget.buildTextWithEdit(
                    '${I18nKey.level.tr} ${index + 1}',
                    intervals[index],
                    format: (v) => days,
                    extraWidget: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          onTap: () {
                            intervals.insert(index, RxInt(intervals[index].value));
                            parentLogic.update([bodyId]);
                          },
                          child: Text(I18nKey.btnCopy.tr),
                        ),
                        PopupMenuItem<String>(
                          onTap: () {
                            if (intervals.length <= 1) {
                              Snackbar.show(I18nKey.learnIntervalListCantBeEmpty.tr);
                              return;
                            }
                            intervals.removeAt(index);
                            parentLogic.update([bodyId]);
                          },
                          child: Text(I18nKey.btnDelete.tr),
                        ),
                        PopupMenuItem<String>(
                          onTap: () {
                            MsgBox.yes(
                              I18nKey.labelTips.tr,
                              I18nKey.learnIntervalTips.trArgs(['${index + 1}', days]),
                            );
                          },
                          child: Text(I18nKey.labelTips.tr),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
      onTapBlack: close,
    );
  }

  void close() {
    var same = isSame();
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
      yes: () async {
        await save();
        Get.back();
        Get.back();
      },
    );
  }

  bool isSame() {
    List<int> a = ScheduleDao.scheduleConfig.learnIntervalDays;
    List<int> b = [0];
    for (var index = 0; index < intervals.length; index++) {
      b.add(intervals[index].value);
    }
    String aStr = json.encode(a);
    String bStr = json.encode(b);
    return aStr == bStr;
  }

  Future<void> save() async {
    List<int> learnIntervalDays = [0];
    for (var index = 0; index < intervals.length; index++) {
      learnIntervalDays.add(intervals[index].value);
    }
    ScheduleDao.scheduleConfig.learnIntervalDays = learnIntervalDays;
    String value = json.encode(ScheduleDao.scheduleConfig);
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.todayScheduleConfig, value));
    Snackbar.show(I18nKey.labelSaved.tr);
  }
}
