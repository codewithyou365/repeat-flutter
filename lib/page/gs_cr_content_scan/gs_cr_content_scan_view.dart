import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/qr_scan/qr_scan.dart';

import 'gs_cr_content_scan_logic.dart';

class GsCrContentScanPage extends StatelessWidget {
  const GsCrContentScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrContentScanLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.scan.tr),
      ),
      body: QrScan(logic.onResult, key: logic.state.qrScanKey),
    );
  }
}
