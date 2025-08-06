import 'package:flutter/cupertino.dart';
import 'helper.dart';

abstract class RepeatView {
  Helper? helper;

  void init(Helper helper);

  void dispose();

  Widget body();
}
