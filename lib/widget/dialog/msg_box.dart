import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
      barrierDismissible: false,
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
    String? qrPagePath,
  }) {
    final tec = TextEditingController(text: model.value);
    Widget? suffixIcon;
    if (qrPagePath != null) {
      suffixIcon = IconButton(
        icon: const Icon(Icons.qr_code),
        onPressed: () async {
          var value = await Get.toNamed(qrPagePath);
          if (value != null && value is String && value != "") {
            tec.text = value;
          }
        },
      );
    }

    Get.defaultDialog(
      title: title,
      barrierDismissible: false,
      content: TextFormField(
        controller: tec,
        decoration: InputDecoration(
          labelText: decoration,
          suffixIcon: suffixIcon,
        ),
      ),
      actions: yesOrNoAction(
          yes: () {
            model.value = tec.text.trim();
            if (yes != null) {
              yes();
            } else {
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

  static yesWithQrCode(
    String title,
    String qrContent,
    String desc, {
    GestureTapCallback? tapQrCode,
    VoidCallback? yes,
    String? yesBtnTitle,
    double? size,
  }) {
    size ??= 200.w;
    Color color = Colors.black;
    if (Get.context != null) {
      color = Theme.of(Get.context!).brightness == Brightness.dark ? color = Colors.white : Colors.black;
    }
    Get.defaultDialog(
      title: title,
      content: Column(
        children: [
          InkWell(
            onTap: tapQrCode,
            child: SizedBox(
              width: size,
              height: size,
              child: QrImageView(
                data: qrContent,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: color,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: color,
                ),
                version: QrVersions.auto,
                size: size,
              ),
            ),
          ),
          Text(desc),
        ],
      ),
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
