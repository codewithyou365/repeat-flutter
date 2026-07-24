import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';

class RepeatArgs {
  final List<VerseTodayPrg> progresses;
  final int startIndex;
  final RepeatType repeatFlowType;
  final ShowMode showMode;
  final bool enableShowRecallButtons;

  /// When true, the repeat page persists the last browsed verse to
  /// [CrK.lastBrowseVerseId] on close, so "全局浏览" can resume next time.
  final bool saveGlobalBrowsePosition;

  RepeatArgs({
    required this.progresses,
    required this.startIndex,
    required this.repeatFlowType,
    required this.enableShowRecallButtons,
    required this.showMode,
    this.saveGlobalBrowsePosition = false,
  });
}
