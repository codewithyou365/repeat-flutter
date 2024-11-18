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
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text(I18nKey.statisticLearn.tr),
            onTap: () {
              Nav.gsCrStatsLearn.push();
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart),
            title: Text(I18nKey.statisticReview.tr),
            onTap: () {
              Nav.gsCrStatsReview.push();
            },
          ),
        ],
      ),
    );
  }
}
