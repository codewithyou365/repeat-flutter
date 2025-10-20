import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse_stats.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/date/calendar_widget.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

class CalendarLogic<T extends GetxController> {
  Map<int, int> learnCount = {};
  Map<int, int> reviewCount = {};
  Map<int, int> fullCustomCount = {};

  DateTime focusedDay = DateTime.now();
  final T parentLogic;
  final String id;

  CalendarLogic(this.parentLogic, [this.id = "CalendarLogic"]);

  void init() async {
    await onPageChanged(focusedDay);
  }

  Future<void> onPageChanged(DateTime focusedDay) async {
    learnCount = {};
    reviewCount = {};
    fullCustomCount = {};
    Date monthStart = Date.from(DateTime(focusedDay.year, focusedDay.month - 1, 1));
    Date monthEnd = Date.from(DateTime(focusedDay.year, focusedDay.month + 2, 1));
    List<VerseStats> data = await Db().db.statsDao.getStatsByDateRange(Classroom.curr, monthStart, monthEnd);
    for (var e in data) {
      if (e.type == TodayPrgType.learn.index) {
        learnCount.update(e.createDate.value, (count) => count + 1, ifAbsent: () => 1);
      } else if (e.type == TodayPrgType.review.index) {
        reviewCount.update(e.createDate.value, (count) => count + 1, ifAbsent: () => 1);
      } else if (e.type == TodayPrgType.fullCustom.index) {
        fullCustomCount.update(e.createDate.value, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    this.focusedDay = focusedDay;
    parentLogic.update([id]);
  }

  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18.0, top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  I18nKey.labelCalendar.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // IconButton(
                //   onPressed: () {},
                //   icon: const Icon(Icons.arrow_forward_ios),
                // ),
              ],
            ),
          ),
          GetBuilder<T>(
            id: this.id,
            builder: (_) => buildCalendar(context, parentLogic),
          ),
        ],
      ),
    );
  }

  Widget buildCalendar(BuildContext context, T logic) {
    return CalendarWidget.buildTableCalendar(
      focusedDay,
      onPageChanged: this.onPageChanged,
      onDayTap: (day) {
        var value = Date.from(day).value;
        final learnCount = this.learnCount[value] ?? 0;
        final reviewCount = this.reviewCount[value] ?? 0;
        final fullCustomCount = this.fullCustomCount[value] ?? 0;
        Sheet.showBottomSheet(
          context,
          ListView(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RowWidget.buildText(I18nKey.labelLearnCount.tr, '$learnCount'),
                  RowWidget.buildDividerWithoutColor(),
                  RowWidget.buildText(I18nKey.labelReviewCount.tr, '$reviewCount'),
                  RowWidget.buildDividerWithoutColor(),
                  RowWidget.buildText(I18nKey.labelFullCustomCount.tr, '$fullCustomCount'),
                ],
              )
            ],
          ),
          rate: 1 / 3,
        );
      },
      getDayDescribe: (day) {
        var value = Date.from(day).value;
        final learnCount = this.learnCount[value] ?? 0;
        final reviewCount = this.reviewCount[value] ?? 0;
        final fullCustomCount = this.fullCustomCount[value] ?? 0;
        if (learnCount == 0 && reviewCount == 0 && fullCustomCount == 0) {
          return '';
        }
        return fullCustomCount > 0 ? '$learnCount/$reviewCount/$fullCustomCount' : '$learnCount/$reviewCount';
      },
    );
  }
}
