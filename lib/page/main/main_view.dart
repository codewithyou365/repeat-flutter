import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'main_logic.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainLogic>();
    final state = Get.find<MainLogic>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  padding: EdgeInsets.only(right: 40.w),
                  child: InkWell(
                    onTap: () => {Nav.mainSettings.push()},
                    child: Text(I18nKey.settings.tr),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              // Distribute buttons evenly
              children: [
                InkWell(
                  onTap: () => {Nav.mainContent.push()},
                  child: Text(I18nKey.content.tr),
                ),
                InkWell(
                  onTap: () => {},
                  child: Text(I18nKey.statistic.tr),
                ),
              ],
            ),
            Container(padding: EdgeInsets.all(16.w))
          ],
        ),
      ),
    );
  }
}
