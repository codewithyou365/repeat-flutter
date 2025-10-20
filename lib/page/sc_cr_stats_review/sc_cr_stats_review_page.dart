import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/date/calendar_widget.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'sc_cr_stats_review_logic.dart';

class ScCrStatsReviewPage extends StatelessWidget {
  const ScCrStatsReviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrStatsReviewLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statisticReview.tr),
      ),
      body: buildWidget(context, logic),
    );
  }

  Widget buildWidget(BuildContext context, ScCrStatsReviewLogic logic) {
    return GetBuilder<ScCrStatsReviewLogic>(
      id: ScCrStatsReviewLogic.id,
      builder: (_) => _buildWidget(context, logic),
    );
  }

  Widget _buildWidget(BuildContext context, ScCrStatsReviewLogic logic) {
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
            Sheet.showBottomSheet(
              context,
              ListView(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RowWidget.buildText(I18nKey.labelLearnCount.tr, '$learnCount'),
                      RowWidget.buildDividerWithoutColor(),
                      RowWidget.buildText(I18nKey.labelReviewThisCount.tr, '$reviewCount'),
                    ],
                  )
                ],
              ),
              rate: 1 / 3,
            );
          },
          getDayDescribe: (day) {
            var value = Date.from(day).value;
            final minCount = state.minCount[value] ?? -1;
            if (minCount == -1) {
              return '';
            }
            return '$minCount';
          },
        ),
      ],
    );
  }
}
