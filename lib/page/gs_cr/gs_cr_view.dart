import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'gs_cr_logic.dart';

class GsCrPage extends StatelessWidget {
  const GsCrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrLogic>();
    final state = Get.find<GsCrLogic>().state;
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
                    onTap: () => {
                      // TODO classroom settings learn config
                      Nav.gsCrSettings.push()
                    },
                    child: Text(I18nKey.settings.tr),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Obx(() {
                return Text(state.learnDeadlineTips.value);
              }),
            ),
            SizedBox(
              width: 300.w,
              child: buildButton(
                context,
                logic.tryLearn,
                I18nKey.btnRepeat.tr,
                Obx(() {
                  return Text(
                    "${state.learnTotalCount.value}",
                  );
                }),
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
                  onTap: () => {Nav.gsCrContent.push()},
                  child: Text(I18nKey.content.tr),
                ),
                InkWell(
                  onTap: () => {Nav.gsCrStats.push()},
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

  Widget buildButton(BuildContext context, VoidCallback? press, String title, ObxWidget text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        minimumSize: Size(140.w, 60.w),
      ),
      onPressed: press,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0.h),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                  color: Theme.of(context).shadowColor,
                )),
            text,
          ],
        ),
      ),
    );
  }
}
