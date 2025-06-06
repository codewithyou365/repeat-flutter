import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/verse_overall_prg_with_key.dart';

import 'gs_cr_stats_learn_logic.dart';

class GsCrStatsLearnPage extends StatelessWidget {
  const GsCrStatsLearnPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrStatsLearnLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statisticLearn.tr),
      ),
      body: buildList(context, logic),
    );
  }

  Widget buildList(BuildContext context, GsCrStatsLearnLogic logic) {
    return GetBuilder<GsCrStatsLearnLogic>(
      id: GsCrStatsLearnLogic.id,
      builder: (_) => _buildList(context, logic),
    );
  }

  Widget _buildList(BuildContext context, GsCrStatsLearnLogic logic) {
    final state = logic.state;
    if (state.progress.isEmpty) {
      return Text(I18nKey.labelNoContent.tr);
    }
    return ListView(
      children: List.generate(state.progress.length, (index) => buildItem(context, logic, state.progress[index])),
    );
  }

  Widget buildItem(BuildContext context, GsCrStatsLearnLogic logic, VerseOverallPrgWithKey model) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Text(model.toKey()),
          const Spacer(),
          Text("${model.next.value}"),
          const Spacer(),
          Text("${model.progress}"),
        ],
      ),
    );
  }
}
