import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'gs_cr_content_share_logic.dart';

class GsCrContentSharePage extends StatelessWidget {
  const GsCrContentSharePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrContentShareLogic>();
    var state = logic.state;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.contentShare.tr),
      ),
      body: Column(
        children: [
          Text(I18nKey.labelOriginalAddress.tr),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(state.originalAddress),
          ),
          Text(I18nKey.labelLanAddress.tr),
          Obx(() {
            return Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(state.lanAddress.value),
            );
          }),
        ],
      ),
    );
  }
}
