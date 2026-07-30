import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'sc_cr_stats_trend_logic.dart';

class ScCrStatsTrendPage extends StatelessWidget {
  const ScCrStatsTrendPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrStatsTrendLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statisticTrend.tr),
      ),
      body: GetBuilder<ScCrStatsTrendLogic>(
        id: ScCrStatsTrendLogic.id,
        builder: (_) => ListView(
          children: <Widget>[
            const SizedBox(height: 16),
            logic.volumeChartLogic.build(context),
            const SizedBox(height: 16),
            logic.timeChartLogic.build(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
