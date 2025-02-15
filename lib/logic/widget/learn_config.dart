import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:repeat_flutter/i18n/i18n_key.dart';

class LearnConfig<T extends GetxController> {
  static void agentClick(VoidCallback cb) {
    cb();
    Get.back();
  }

  static Widget buttonGroup(VoidCallback copy, VoidCallback delete, VoidCallback update) {
    return Row(
      children: [
        TextButton(
          child: Text(I18nKey.btnCopy.tr),
          onPressed: () {
            agentClick(copy);
          },
        ),
        const Spacer(),
        TextButton(
          child: Text(I18nKey.btnDelete.tr),
          onPressed: () {
            agentClick(delete);
          },
        ),
        const Spacer(),
        TextButton(
          child: Text(I18nKey.btnOk.tr),
          onPressed: () {
            agentClick(update);
          },
        ),
      ],
    );
  }
}
