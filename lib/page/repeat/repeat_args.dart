import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';

class RepeatArgs {
  final List<VerseTodayPrg> progresses;
  final int startIndex;
  final RepeatType repeatType;
  final ShowMode showMode;
  final bool enableShowRecallButtons;

  RepeatArgs({
    required this.progresses,
    required this.startIndex,
    required this.repeatType,
    required this.enableShowRecallButtons,
    required this.showMode,
  });
}
