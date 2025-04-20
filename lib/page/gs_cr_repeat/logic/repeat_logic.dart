import 'package:repeat_flutter/db/entity/segment_today_prg.dart';

import 'constant.dart';

abstract class RepeatLogic {
  late Function() update;

  RepeatStep get step;

  SegmentTodayPrg? get currSegment;

  SegmentTodayPrg? get nextSegment;

  String get titleLabel;

  String get leftLabel;

  String get rightLabel;

  Future<bool> init(List<SegmentTodayPrg> all, Function() update);

  void onClose();

  void onTapLeft();

  void onTapRight();

  Function()? getLongTapRight() {
    return null;
  }

  Future<void> jump({required int progress, required int nextDayValue});
}
