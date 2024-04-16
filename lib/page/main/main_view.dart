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
            SizedBox(
              height: 60.w,
              width: 200.w,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).secondaryHeaderColor,
                ),
                onPressed: () => {
                  logic.tryMainRepeat(),
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 11.0.w),
                  child: Column(
                    children: [
                      Text(I18nKey.btnRepeat.tr,
                          style: TextStyle(
                            color: Theme.of(context).shadowColor,
                          )),
                      Obx(() {
                        return Text(
                          "${state.totalCount.value}",
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 80.w,
            ),
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
            SizedBox(
              height: 30.w,
            ),
          ],
        ),
      ),
    );
  }
}
