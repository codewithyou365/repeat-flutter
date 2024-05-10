import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
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
    if (state.progress.isEmpty) {
      return Text(I18nKey.labelNoContent.tr);
    }
    return ListView(
      children: List.generate(state.progress.length, (index) => buildItem(context, logic, state.progress[index])),
    );
  }

  Widget buildItem(BuildContext context, GsCrStatsReviewLogic logic, SegmentReview model) {
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
