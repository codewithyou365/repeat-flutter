import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

class EditProgress {
  static Future<void> show(int verseId, {String? warning, String? title, Future<void> Function(int p, int n)? callback}) async {
    var verseProgress = await Db().db.scheduleDao.getVerseProgress(verseId);
    if (verseProgress == null) {
      return;
    }
    var progress = (verseProgress + 1).obs;
    var nextDay = ScheduleDao.getNextByProgress(Date.now(), progress.value).value.obs;
    return Sheet.showBottomSheet(
      Get.context!,
      Obx(() {
        return ListView(
          children: [
            RowWidget.buildYesOrNo(
              yesBtnTitle: I18nKey.btnCancel.tr,
              noBtnTitle: title,
              no: () {
                showTransparentOverlay(() async {
                  if (callback != null) {
                    await callback(progress.value, nextDay.value);
                  }
                });
              },
            ),
            if (warning != null)
              RowWidget.buildMiddleText(
                warning,
                ts: const TextStyle(fontSize: RowWidget.titleFontSize, color: Colors.red),
              ),
            if (warning != null) RowWidget.buildDivider(),
            RowWidget.buildMiddleText(I18nKey.labelAdjustLearnProgressDesc.trArgs(["$verseProgress"])),
            RowWidget.buildDivider(),
            RowWidget.buildCupertinoPicker(
              title: I18nKey.level.tr,
              options: List.generate(verseProgress + ScheduleDao.scheduleConfig.learnIntervalDays.length, (i) {
                return '$i';
              }),
              value: progress,
              changed: (value) {
                progress.value = value;
                nextDay.value = ScheduleDao.getNextByProgress(ScheduleDao.currentDate(), value).value;
              },
            ),
            RowWidget.buildDividerWithoutColor(),
            RowWidget.buildDateWithEdit(I18nKey.labelSetNextLearnDate.tr, nextDay, Get.context!),
          ],
        );
      }),
    );
  }
}
