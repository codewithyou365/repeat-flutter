import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/tip.dart';
import 'package:repeat_flutter/logic/tip_server/web_server.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_args.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_logic.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'tip_state.dart';

class TipLogic<T extends GetxController> {
  static const int defaultPort = 4325;
  RxInt port = defaultPort.obs;
  final T parentLogic;
  late TipWebServer web;
  final WebviewLogic webviewLogic = WebviewLogic();

  final TipState state = TipState();

  TipLogic({
    required this.parentLogic,
    required VoidCallback tapNext,
    required VoidCallback tapLeft,
    required VoidCallback tapRight,
    required VoidCallback tapMiddle,
    required VoidCallback longTapMiddle,
  }) {
    web = TipWebServer(
      tapNext: tapNext,
      tapLeft: tapLeft,
      tapRight: tapRight,
      tapMiddle: tapMiddle,
      longTapMiddle: longTapMiddle,
    );
  }

  Future<void> openTipSheet(BuildContext context, Tip tip) async {
    if (state.openPending) {
      return;
    }
    state.openPending = true;
    try {
      await _startTipWeb(tip);
      final args = WebviewArgs(
        initialUrl: "http://127.0.0.1:${port.value}",
        pageTitle: tip.k,
        showTopBar: false,
      );
      await Sheet.showBottomSheet<void>(
        context,
        webviewLogic.build(args, () async {
          await _closeTipWeb(closeSheet: true);
        }, context),
        padding: EdgeInsets.zero,
      );
    } finally {
      await _closeTipWeb(closeSheet: true);
      state.openPending = false;
    }
  }

  Future<void> _startTipWeb(Tip tip) async {
    TipState.tip = tip;
    port.value = await Db().db.kvDao.getIntWithDefault(K.tipServerPort, port.value);
    if (port.value > 50000) {
      port.value = defaultPort;
    }
    await web.start(tip.bookId, tip.hash, tip.service, port.value);
  }

  Future<void> _closeTipWeb({bool closeSheet = false}) async {
    if (closeSheet && Get.isBottomSheetOpen == true) {
      Get.back();
    }
    await closeWeb();
    TipState.tip = null;
  }

  Future<void> closeWeb() async {
    try {
      await web.stop();
    } catch (e) {
      return;
    }
  }
}
