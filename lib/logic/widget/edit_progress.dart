import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

class EditProgress {
  static void show(int segmentKeyId, {String? warning, String? title, Future<void> Function(int p, int n)? callback}) async {
    var segmentProgress = await Db().db.scheduleDao.getSegmentProgress(segmentKeyId);
    if (segmentProgress == null) {
      return;
    }
    var progress = (segmentProgress + 1).obs;
    var nextDay = ScheduleDao.getNextByProgress(DateTime.now(), progress.value).value.obs;
    Sheet.showBottomSheet(Get.context!, Obx(() {
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
          if (warning != null) RowWidget.buildMiddleText(warning, ts: const TextStyle(fontSize: RowWidget.titleFontSize, color: Colors.red)),
          if (warning != null) RowWidget.buildDivider(),
          RowWidget.buildMiddleText(I18nKey.labelAdjustLearnProgressDesc.trArgs(["$segmentProgress"])),
          RowWidget.buildDivider(),
          RowWidget.buildCupertinoPicker(
            I18nKey.labelSetLevel.tr,
            List.generate(segmentProgress + ScheduleDao.scheduleConfig.forgettingCurve.length, (i) {
              return '$i';
            }),
            progress,
            changed: (value) {
              progress.value = value;
              nextDay.value = ScheduleDao.getNextByProgress(DateTime.now(), value).value;
            },
          ),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildDateWithEdit(I18nKey.labelSetNextLearnDate.tr, nextDay, Get.context!),
        ],
      );
    }));
  }
}
