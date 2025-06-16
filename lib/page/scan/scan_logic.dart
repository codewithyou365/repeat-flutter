import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'scan_state.dart';

class ScanLogic extends GetxController {
  final ScanState state = ScanState();

  onResult(String code) {
    state.qrScanKey.currentState?.pauseCamera();
    MsgBox.yesOrNo(
      title: I18nKey.labelShouldScannedContentBeAdded.tr,
      desc: code,
      no: () {
        Get.back();
        state.qrScanKey.currentState?.resumeCamera();
      },
      yes: () {
        Get.back();
        Get.back(result: code);
      },
    );
  }
}
