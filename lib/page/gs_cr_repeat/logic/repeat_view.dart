import 'package:flutter/cupertino.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/helper.dart';

abstract class RepeatView {
  Helper? helper;

  void init(Helper helper);

  Widget body({required double height});
}
