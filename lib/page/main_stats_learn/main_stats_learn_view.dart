import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'main_stats_learn_logic.dart';

class MainStatsLearnPage extends StatelessWidget {
  const MainStatsLearnPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainStatsLearnLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statisticLearn.tr),
      ),
      body: buildList(context, logic),
    );
  }

  Widget buildList(BuildContext context, MainStatsLearnLogic logic) {
    return GetBuilder<MainStatsLearnLogic>(
      id: MainStatsLearnLogic.id,
      builder: (_) => _buildList(context, logic),
    );
  }

  Widget _buildList(BuildContext context, MainStatsLearnLogic logic) {
    final state = logic.state;
    if (state.progress.isEmpty) {
      return Text(I18nKey.labelNoContent.tr);
    }
    return ListView(
      children: List.generate(state.progress.length, (index) => buildItem(context, logic, state.progress[index])),
    );
  }

  Widget buildItem(BuildContext context, MainStatsLearnLogic logic, SegmentOverallPrg model) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Text(model.k),
          const Spacer(),
          Text("${model.next.value}"),
          const Spacer(),
          Text("${model.progress}"),
        ],
      ),
    );
  }
}
