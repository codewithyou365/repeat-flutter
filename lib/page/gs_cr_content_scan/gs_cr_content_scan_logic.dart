import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'gs_cr_content_scan_state.dart';

class GsCrContentScanLogic extends GetxController {
  final GsCrContentScanState state = GsCrContentScanState();

  onResult(String code) {
    state.qrScanKey.currentState?.pauseCamera();
    MsgBox.yesOrNo(
      title: I18nKey.labelShouldLinkToTheContentBeAdded.tr,
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
