import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

enum InputType {
  number,
  normal,
}

class MsgBox {
  static yesOrNo(
    String title,
    String desc, {
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
    bool barrierDismissible = false,
  }) {
    Get.defaultDialog(
      title: title,
      barrierDismissible: barrierDismissible,
      content: Text(desc),
      actions: yesOrNoAction(yes: yes, no: no, yesBtnTitle: yesBtnTitle, noBtnTitle: noBtnTitle),
    );
  }

  static switchWithYesOrNo(
    String title,
    String desc,
    RxBool select,
    String selectDesc, {
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
  }) {
    Get.defaultDialog(
      title: title,
      barrierDismissible: false,
      content: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              desc,
              softWrap: true,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Obx(() {
                  return Switch(
                      value: select.value,
                      onChanged: (bool value) {
                        select.value = value;
                      });
                }),
                SizedBox(
                  width: 180.w,
                  child: Text(
                    selectDesc,
                    softWrap: true,
                  ),
                ), //error
              ],
            ),
          ],
        ),
      ),
      actions: yesOrNoAction(yes: yes, no: no, yesBtnTitle: yesBtnTitle, noBtnTitle: noBtnTitle),
    );
  }

  static strInputWithYesOrNo(
    Rx model,
    String title,
    String? decoration, {
    InputType? inputType,
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
    String? qrPagePath,
    int? maxLines = 1,
    int? minLines,
    barrierDismissible = false,
    List<Widget>? nextChildren,
  }) {
    if (inputType == null) {
      if (model is RxString) {
        inputType = InputType.normal;
      } else {
        inputType = InputType.number;
      }
    }
    final tec = TextEditingController(text: model.value.toString());
    Widget? suffixIcon;
    if (qrPagePath != null) {
      suffixIcon = IconButton(
        icon: const Icon(Icons.qr_code_scanner),
        onPressed: () async {
          var value = await Get.toNamed(qrPagePath);
          if (value != null && value is String && value != "") {
            tec.text = value;
          }
        },
      );
    }
    TextInputType? keyboardType;
    List<TextInputFormatter>? inputFormatters;
    if (inputType == InputType.number) {
      keyboardType = TextInputType.number;
      inputFormatters = <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];
    }
    var children = <Widget>[
      TextFormField(
        controller: tec,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: decoration,
          suffixIcon: suffixIcon,
        ),
      ),
    ];
    if (nextChildren != null) {
      children.addAll(nextChildren);
    }
    Get.defaultDialog(
      title: title,
      barrierDismissible: barrierDismissible,
      content: Column(
        children: children,
      ),
      actions: yesOrNoAction(
          yes: () {
            var t = tec.text.trim();
            if (model is RxString) {
              model.value = t;
            } else if (model is RxInt) {
              model.value = int.tryParse(t) ?? 0;
            } else if (model is RxDouble) {
              model.value = double.tryParse(t) ?? 0.0;
            } else if (model is RxBool) {
              model.value = (t.toLowerCase() == 'true');
            } else {
              print("Unsupported Rx type");
            }

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
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
        ),
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

  static noWithQrCode(
    String title,
    String qrContent,
    String? desc, {
    VoidCallback? no,
    String? noBtnTitle,
    double? size,
  }) {
    size ??= 250.w;
    Color color = Colors.black;
    if (Get.context != null) {
      color = Theme.of(Get.context!).brightness == Brightness.dark ? color = Colors.white : Colors.black;
    }
    Get.defaultDialog(
      title: title,
      content: Column(
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(0),
            child: Center(
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
          if (desc != null) Text(desc),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (no != null) {
              no();
            } else {
              Get.back();
            }
          },
          child: Text(noBtnTitle ?? I18nKey.btnCancel.tr),
        ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: qrContent));
            Snackbar.show(I18nKey.labelQrCodeContentCopiedToClipboard.tr);
          },
          child: Text(I18nKey.btnCopy.tr),
        ),
      ],
    );
  }
}
