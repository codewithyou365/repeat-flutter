import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/editor.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'editor_args.dart';
import 'editor_state.dart';

class EditorLogic extends GetxController {
  static const String id = "EditorLogic";
  final EditorState state = EditorState();
  final textController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    var args = Get.arguments as EditorArgs;
    if (args.onHistory != null) {
      state.historyBtn = Button(I18nKey.btnHistory.tr, args.onHistory);
    }
    state.shareBtn = Button(I18nKey.btnShare.tr, () {
      Editor.showQrCode(Get.context!, textController.text);
    });
    state.scanBtn = Button(I18nKey.scan.tr, () async {
      var v = await Get.toNamed(Nav.scan.path);
      if (v != null && v is String && v != "") {
        Get.back();
        textController.text = v;
      }
    });
    state.save = Button(I18nKey.btnSave.tr, () async {
      await args.save(textController.text);
      state.dbValue = textController.text;
      textChange();
      Snackbar.show(I18nKey.labelSaved.tr);
    });
    textController.addListener(textChange);
    textController.text = args.value;

    state.title = args.title;
    state.initShowValue = args.value;
    state.dbValue = args.value;
  }

  void textChange() {
    state.shareBtn.enable.value = textController.text == state.dbValue;
    state.scanBtn.enable.value = textController.text == state.dbValue;
  }

  @override
  void onClose() {
    super.onClose();
  }
}
