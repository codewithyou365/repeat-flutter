import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'main_stats_logic.dart';

class MainStatsPage extends StatelessWidget {
  const MainStatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.statistic.tr),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(I18nKey.statisticLearn.tr),
            onTap: () {
              Nav.mainStatsLearn.push();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(I18nKey.statisticReview.tr),
            onTap: () {
              Nav.mainStatsReview.push();
            },
          ),
        ],
      ),
    );
  }
}
