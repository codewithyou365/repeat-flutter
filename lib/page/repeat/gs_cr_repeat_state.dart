import 'logic/helper.dart';

class GsCrRepeatState {
  bool? lastLandscape;
  bool needUpdateSystemUiMode = true;

  var concentrationMode = true;
  Helper helper = Helper();
  late double bodyHeight;
  var showBottomBar = true;

  var lastRecallTime = 0;
}
