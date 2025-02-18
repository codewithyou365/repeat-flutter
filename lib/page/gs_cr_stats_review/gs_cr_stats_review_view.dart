import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:table_calendar/table_calendar.dart';
import 'gs_cr_stats_review_logic.dart';

class GsCrStatsReviewPage extends StatelessWidget {
  const GsCrStatsReviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrStatsReviewLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statisticReview.tr),
      ),
      body: buildList(context, logic),
    );
  }

  Widget buildList(BuildContext context, GsCrStatsReviewLogic logic) {
    return GetBuilder<GsCrStatsReviewLogic>(
      id: GsCrStatsReviewLogic.id,
      builder: (_) => _buildList(context, logic),
    );
  }

  Widget _buildList(BuildContext context, GsCrStatsReviewLogic logic) {
    final state = logic.state;
    return TableCalendar(
      firstDay: DateTime.utc(2024, 3, 21),
      lastDay: DateTime.utc(2100, 3, 14),
      focusedDay: state.focusedDay,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
      ),
      onPageChanged: logic.onPageChanged,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          var value = Date.from(day).value;
          final num = state.number[value];
          final min = state.minCount[value];
          if (num == null) {
            return null;
          }
          return Center(
            child: InkWell(
              onTap: () {
                MsgBox.yes(
                  I18nKey.labelTips.tr,
                  '${I18nKey.labelExamineCount.tr}:$min\n${I18nKey.labelSegmentNumber.tr}:$num',
                );
              },
              child: Column(
                children: [
                  Text('${day.day}'),
                  Text(
                    '$min/$num',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
