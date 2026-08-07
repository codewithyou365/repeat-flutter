import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/tip.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_args.dart';

import 'logic/helper.dart';

class RepeatState {
  bool? lastLandscape;
  bool needUpdateSystemUiMode = true;
  bool systemUiVisible = false;

  var enableShowRecallButtons = false;
  WebviewArgs? webviewArgs;
  var fullScreenMode = Rx<RepeatFullScreenMode>(RepeatFullScreenMode.none);

  var closeEyesDirect = 0;
  var enableCloseEyesMode = Rx<CloseEyesModeEnum>(CloseEyesModeEnum.opacity);

  Helper helper = Helper();
  late double bodyHeight;
  var showBottomBar = true;

  var lastRecallTime = 0;

  RxBool isPracticeMode = false.obs;

  bool gameLogicInitSuccess = false;

  /// 'q'/'a'/'n' 的提示服务：每本书各配各的。
  Map<int, Map<String, Tip?>> bookIdToTip = {};

  /// 提示（'t'/'t1'/…）的提示服务：整个课堂共用一套，见 ClassroomDocField.tips。
  Map<String, Tip?> classroomTips = {};
}
