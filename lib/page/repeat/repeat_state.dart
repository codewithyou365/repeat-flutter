import 'logic/helper.dart';

class RepeatState {
  bool? lastLandscape;
  bool needUpdateSystemUiMode = true;

  var concentrationMode = true;
  var enableShowRecallButtons = false;
  Helper helper = Helper();
  late double bodyHeight;
  var showBottomBar = true;

  var lastRecallTime = 0;
}
