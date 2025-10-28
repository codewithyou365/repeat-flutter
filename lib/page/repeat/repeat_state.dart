import 'package:get/get.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

import 'logic/helper.dart';

class RepeatState {
  bool? lastLandscape;
  bool needUpdateSystemUiMode = true;

  var enableShowRecallButtons = false;
  var closeEyesDirect = 0;
  var enableCloseEyesMode = Rx<CloseEyesEnum>(CloseEyesEnum.none);
  Helper helper = Helper();
  late double bodyHeight;
  var showBottomBar = true;

  var lastRecallTime = 0;
}
