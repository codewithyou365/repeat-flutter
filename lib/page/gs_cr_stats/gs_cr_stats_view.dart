import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'gs_cr_stats_logic.dart';

class GsCrStatsPage extends StatelessWidget {
  const GsCrStatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statistic.tr),
      ),
      body: GetBuilder<GsCrStatsLogic>(
          id: GsCrStatsLogic.id,
          builder: (logic) {
            return ListView(
              children: <Widget>[
                logic.progressLogic.build(context),
                const SizedBox(height: 16),
                logic.summaryLogic.build(context),
                const SizedBox(height: 16),
                logic.calendarLogic.build(context),
              ],
            );
          }),
    );
  }
}
