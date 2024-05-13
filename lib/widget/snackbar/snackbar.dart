import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

class Snackbar {
  static List<SnackbarController> snackbar = [];
  static int finishCount = 0;

  static show(String content) {
    if (finishCount == snackbar.length) {
      finishCount = 0;
      snackbar = [];
    } else {
      snackbar[snackbar.length - 1].close(withAnimations: false);
    }
    var sb = Get.snackbar(
      I18nKey.labelTips.tr,
      content,
    );
    sb.future.whenComplete(() {
      finishCount++;
      if (finishCount == snackbar.length) {
        finishCount = 0;
        snackbar = [];
      }
    });
    snackbar.add(sb);
  }
}
