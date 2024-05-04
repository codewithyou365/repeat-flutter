import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/page/main_stats_review/main_stats_review_logic.dart';

class MainStatsReviewPage extends StatelessWidget {
  const MainStatsReviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainStatsReviewLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statisticReview.tr),
      ),
      body: buildList(context, logic),
    );
  }

  Widget buildList(BuildContext context, MainStatsReviewLogic logic) {
    return GetBuilder<MainStatsReviewLogic>(
      id: MainStatsReviewLogic.id,
      builder: (_) => _buildList(context, logic),
    );
  }

  Widget _buildList(BuildContext context, MainStatsReviewLogic logic) {
    final state = logic.state;
    if (state.progress.isEmpty) {
      return Text(I18nKey.labelNoContent.tr);
    }
    return ListView(
      children: List.generate(state.progress.length, (index) => buildItem(context, logic, state.progress[index])),
    );
  }

  Widget buildItem(BuildContext context, MainStatsReviewLogic logic, SegmentReview model) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Text("${model.createDate.value}"),
          const Spacer(),
          Text(model.k),
          const Spacer(),
          Text("${model.count}"),
        ],
      ),
    );
  }
}
