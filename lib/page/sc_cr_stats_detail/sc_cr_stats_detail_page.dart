import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/date/calendar_widget.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'sc_cr_stats_detail_logic.dart';

class ScCrStatsDetailPage extends StatelessWidget {
  const ScCrStatsDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrStatsDetailLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statisticDetail.tr),
      ),
      body: buildWidget(context, logic),
    );
  }

  Widget buildWidget(BuildContext context, ScCrStatsDetailLogic logic) {
    return GetBuilder<ScCrStatsDetailLogic>(
      id: ScCrStatsDetailLogic.id,
      builder: (_) => _buildWidget(context, logic),
    );
  }

  Widget _buildWidget(BuildContext context, ScCrStatsDetailLogic logic) {
    var state = logic.state;
    return ListView(
      children: [
        CalendarWidget.buildTableCalendar(
          state.focusedDay,
          onPageChanged: logic.onPageChanged,
          onDayTap: (day) {
            var value = Date.from(day).value;
            final learnCount = state.learnCount[value] ?? 0;
            final reviewCount = state.reviewCount[value] ?? 0;
            final fullCustomCount = state.fullCustomCount[value] ?? 0;
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
            final learnCount = state.learnCount[value] ?? 0;
            final reviewCount = state.reviewCount[value] ?? 0;
            final fullCustomCount = state.fullCustomCount[value] ?? 0;
            if (learnCount == 0 && reviewCount == 0 && fullCustomCount == 0) {
              return '';
            }
            return fullCustomCount > 0 ? '$learnCount/$reviewCount/$fullCustomCount' : '$learnCount/$reviewCount';
          },
        ),
      ],
    );
  }
}
