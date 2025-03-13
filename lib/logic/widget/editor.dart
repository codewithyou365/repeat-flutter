import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class Editor {
  static void show(BuildContext context, String title, String dbValue, Future<void> Function(String) save, {double? rate, String? qrPagePath, String? initShowValue}) {
    initShowValue ??= dbValue;
    final textController = TextEditingController(text: initShowValue.toString());
    final shareBtn = Button(I18nKey.btnShare.tr, () {
      showQrCode(context, textController.text);
    });
    final scanBtn = Button(I18nKey.btnScan.tr, () async {
      if (qrPagePath == null) {
        return;
      }
      var v = await Get.toNamed(qrPagePath);
      if (v != null && v is String && v != "") {
        Get.back();
        show(context, title, dbValue, save, rate: rate, qrPagePath: qrPagePath, initShowValue: v);
      }
    });
    void textChange() {
      shareBtn.enable.value = textController.text == dbValue;
      scanBtn.enable.value = textController.text == dbValue;
    }

    void onCancel() {
      if (textController.text != dbValue) {
        MsgBox.yesOrNo(
          I18nKey.labelTips.tr,
          I18nKey.labelTextChange.tr,
          no: () {
            Get.back();
            Get.back();
          },
          yes: () {
            Get.back();
            Get.back();
            save(textController.text);
          },
          barrierDismissible: true,
        );
      } else {
        Get.back();
      }
    }

    textController.addListener(textChange);
    Sheet.withHeaderAndBody(
      context,
      Column(
        key: GlobalKey(),
        mainAxisSize: MainAxisSize.min,
        children: [
          RowWidget.buildButtons([
            Button(I18nKey.btnCancel.tr, onCancel),
            shareBtn,
            if (qrPagePath != null) scanBtn,
            Button(I18nKey.btnSave.tr, () async {
              await save(textController.text);
              dbValue = textController.text;
              textChange();
              Snackbar.show(I18nKey.labelSaved.tr);
            }),
          ]),
          RowWidget.buildDivider(),
          RowWidget.buildText("$title :", ""),
        ],
      ),
      RowWidget.buildEditText(textController, maxLines: 40, minLines: 32),
      rate: rate,
      onTapBlack: onCancel,
    );
  }

  static void showQrCode(BuildContext context, String value, {double? rate}) {
    final Size screenSize = MediaQuery.of(context).size;
    Sheet.showBottomSheet(
      context,
      ListView(
        children: [
          RowWidget.buildButtons([
            Button(I18nKey.btnCancel.tr),
            Button(I18nKey.btnCopy.tr, () {
              Clipboard.setData(ClipboardData(text: value));
              Snackbar.show(I18nKey.labelQrCodeContentCopiedToClipboard.tr);
            }),
          ]),
          RowWidget.buildDivider(),
          RowWidget.buildQrCode(value, screenSize.width - Sheet.paddingHorizontal * 2),
          RowWidget.buildMiddleText(StringUtil.limit(value.replaceAll("\n", "\\n"), 64), main: false),
        ],
      ),
      rate: rate,
    );
  }
}
