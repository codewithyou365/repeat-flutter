import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class RepeatArgs {
  final List<VerseTodayPrg> progresses;
  final RepeatType repeatType;
  final bool defaultEdit;
  final bool enableShowRecallButtons;

  RepeatArgs({
    required this.progresses,
    required this.repeatType,
    required this.enableShowRecallButtons,
    required this.defaultEdit,
  });
}
