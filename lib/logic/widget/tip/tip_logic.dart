import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/tip.dart';
import 'package:repeat_flutter/logic/tip_server/tip_web_server.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_args.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_logic.dart';
import 'package:repeat_flutter/main.dart';
import 'package:repeat_flutter/page/repeat/logic/tts_helper.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'tip_state.dart';

class TipLogic<T extends GetxController> {
  static const int defaultPort = 4325;
  RxInt port = defaultPort.obs;
  final T parentLogic;
  final TtsHelper ttsHelper;
  late TipWebServer web;
  final WebviewLogic webviewLogic = WebviewLogic();

  final TipState state = TipState();

  TipLogic({
    required this.parentLogic,
    required this.ttsHelper,
    required bool Function() isMute,
    required VoidCallback tapNext,
    required VoidCallback tapLeft,
    required VoidCallback tapRight,
    required VoidCallback tapMiddle,
    required VoidCallback longTapMiddle,
  }) {
    web = TipWebServer(
      ttsHelper: ttsHelper,
      isMute: isMute,
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
      final appLogic = Get.find<MyAppLogic>();
      final theme = appLogic.themeMode.value == ThemeMode.dark ? 'dark' : 'light';
      final args = WebviewArgs(
        initialUrl: "http://127.0.0.1:${port.value}?theme=$theme",
        pageTitle: tip.k,
        showTopBar: false,
        showNavigationBar: false,
      );
      await Sheet.showBottomSheet<void>(
        context,
        webviewLogic.build(args, () async {
          await _closeTipWeb(closeSheet: true);
        }, context),
        padding: EdgeInsets.zero,
        enableDrag: false,
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
