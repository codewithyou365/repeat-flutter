import 'package:repeat_flutter/page/gs_cr_repeat/logic/helper.dart';

class GsCrRepeatState {
  bool? lastLandscape;
  bool needUpdateSystemUiMode = true;

  var concentrationMode = true;
  Helper helper = Helper();
  double bottomBarHeight = 50;
  late double bodyHeight;
  var showBottomBar = true;

  var lastRecallTime = 0;
}
