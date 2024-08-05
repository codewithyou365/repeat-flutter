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
      actions: yesOrNoAction(yes: yes, no: no, yesBtnTitle: yesBtnTitle, noBtnTitle: noBtnTitle),
    );
  }

  static strInputWithYesOrNo(
    RxString model,
    String title,
    String decoration, {
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
  }) {
    final tec = TextEditingController(text: model.value);
    Get.defaultDialog(
      title: title,
      content: TextFormField(
        controller: tec,
        decoration: InputDecoration(
          labelText: decoration,
        ),
      ),
      actions: yesOrNoAction(
          yes: () {
            if (yes != null) {
              yes();
            } else {
              model.value = tec.text.trim();
              Get.back();
            }
          },
          no: no,
          yesBtnTitle: yesBtnTitle,
          noBtnTitle: noBtnTitle),
    );
  }

  static List<Widget> yesOrNoAction({
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
  }) {
    return [
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
    ];
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
