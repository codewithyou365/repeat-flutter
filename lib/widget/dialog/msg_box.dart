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
  static void yesOrNo({
    required String title,
    required String desc,
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
    bool barrierDismissible = false,
  }) {
    myDialog(
      title: title,
      barrierDismissible: barrierDismissible,
      content: content(desc),
      action: yesOrNoAction(yes: yes, no: no, yesBtnTitle: yesBtnTitle, noBtnTitle: noBtnTitle),
    );
  }

  static void checkboxWithYesOrNo({
    required String title,
    String? desc,
    required RxBool select,
    required String selectDesc,
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
  }) {
    myDialog(
      title: title,
      barrierDismissible: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (desc != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                desc,
                softWrap: true,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          if (desc == null) const SizedBox(height: 8),
          Row(
            children: [
              Obx(() {
                return Checkbox(
                  value: select.value,
                  onChanged: (value) {
                    select.value = value ?? false;
                  },
                );
              }),
              Text(
                selectDesc,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ), //error
            ],
          ),
        ],
      ),
      action: yesOrNoAction(yes: yes, no: no, yesBtnTitle: yesBtnTitle, noBtnTitle: noBtnTitle),
    );
  }

  static void strInputWithYesOrNo(
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
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: TextFormField(
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
      ),
    ];
    if (nextChildren != null) {
      children.addAll(nextChildren);
    }
    myDialog(
      title: title,
      barrierDismissible: barrierDismissible,
      content: Column(
        children: children,
      ),
      action: yesOrNoAction(
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
        noBtnTitle: noBtnTitle,
      ),
    );
  }

  static Widget yesOrNoAction({
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
  }) {
    return buttonsWithDivider(
      buttons: [
        button(
          text: noBtnTitle ?? I18nKey.btnCancel.tr,
          onPressed: () {
            if (no != null) {
              no();
            } else {
              Get.back();
            }
          },
        ),
        button(
          text: yesBtnTitle ?? I18nKey.btnOk.tr,
          onPressed: () {
            if (yes != null) {
              yes();
            } else {
              Get.back();
            }
          },
        ),
      ],
    );
  }

  static Future<void> tips({
    required String desc,
    VoidCallback? yes,
    String? yesBtnTitle,
  }) {
    return MsgBox.yes(I18nKey.labelTips.tr, desc, yes: yes, yesBtnTitle: yesBtnTitle);
  }

  static Future<void> yes(
    String title,
    String desc, {
    VoidCallback? yes,
    String? yesBtnTitle,
  }) {
    return myDialog(
      title: title,
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(desc),
      ),
      action: buttonsWithDivider(
        buttons: [
          button(
            text: yesBtnTitle ?? I18nKey.btnOk.tr,
            onPressed: () {
              if (yes != null) {
                yes();
              } else {
                Get.back();
              }
            },
          ),
        ],
      ),
    );
  }

  static void noWithQrCode(
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
    myDialog(
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
          if (desc != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(desc),
            ),
        ],
      ),
      action: buttonsWithDivider(
        buttons: [
          button(
            text: noBtnTitle ?? I18nKey.btnCancel.tr,
            onPressed: () {
              if (no != null) {
                no();
              } else {
                Get.back();
              }
            },
          ),
          button(
            text: I18nKey.btnCopy.tr,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: qrContent));
              Snackbar.show(I18nKey.labelQrCodeContentCopiedToClipboard.tr);
            },
          ),
        ],
      ),
    );
  }

  static Future<void> myDialog({
    String title = "",
    required Widget content,
    required Widget action,
    bool barrierDismissible = true,
  }) {
    if (Get.context == null) {
      return Future<void>(() {});
    }
    const borderRadius = 20.0;

    return showDialog(
      context: Get.context!,
      barrierDismissible: barrierDismissible,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Material(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content,
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                SizedBox(
                  height: 48,
                  child: action,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget content(String text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(text),
    );
  }

  static Widget buttonsWithDivider({
    required List<Widget> buttons,
  }) {
    List<Widget> separated = [];

    for (int i = 0; i < buttons.length; i++) {
      separated.add(buttons[i]);
      if (i != buttons.length - 1) {
        separated.add(Container(width: 1, color: Colors.grey[300]));
      }
    }

    return Row(children: separated);
  }

  static Widget button({required String text, required VoidCallback onPressed}) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.blue.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
