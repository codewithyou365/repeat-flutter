import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

class MsgBox {
  static yesOrNo(
    String title,
    String desc, {
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
  }) {
    Get.defaultDialog(
      title: title,
      content: Text(desc),
      actions: [
        TextButton(
          child: Text(noBtnTitle ?? I18nKey.btnCancel.tr),
          onPressed: () {
            if (no != null) {
              no();
            } else {
              Get.back();
            }
          },
        ),
        TextButton(
          onPressed: () {
            if (yes != null) {
              yes();
            } else {
              Get.back();
            }
          },
          child: Text(yesBtnTitle ?? I18nKey.btnOk.tr),
        ),
      ],
    );
  }

  static yes(
    String title,
    String desc, {
    VoidCallback? yes,
    String? yesBtnTitle,
  }) {
    Get.defaultDialog(
      title: title,
      content: Text(desc),
      actions: [
        TextButton(
          onPressed: () {
            if (yes != null) {
              yes();
            } else {
              Get.back();
            }
          },
          child: Text(yesBtnTitle ?? I18nKey.btnOk.tr),
        ),
      ],
    );
  }
}