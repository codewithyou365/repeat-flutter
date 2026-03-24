import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/tip.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_args.dart';

import 'logic/helper.dart';

class RepeatState {
  bool? lastLandscape;
  bool needUpdateSystemUiMode = true;

  var enableShowRecallButtons = false;
  WebviewArgs? webviewArgs;
  var fullScreenMode = Rx<RepeatFullScreenMode>(RepeatFullScreenMode.none);

  var closeEyesDirect = 0;
  var enableCloseEyesMode = Rx<CloseEyesModeEnum>(CloseEyesModeEnum.opacity);

  Helper helper = Helper();
  late double bodyHeight;
  var showBottomBar = true;

  var lastRecallTime = 0;

  RxInt currentTipTabIndex = 0.obs;

  RxBool isPracticeMode = false.obs;

  bool gameLogicInitSuccess = false;

  Map<int, Map<String, Tip?>> bookIdToTip = {};
}
