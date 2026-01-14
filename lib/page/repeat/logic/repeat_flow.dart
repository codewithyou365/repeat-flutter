import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'game_helper.dart';

import 'constant.dart';
import 'helper.dart';

abstract class RepeatFlow {
  late Function() update;

  late GameHelper gameHelper;
  late Helper helper;

  RepeatStep step = RepeatStep.recall;

  TipLevel tip = TipLevel.none;

  VerseTodayPrg? get currVerse;

  VerseTodayPrg? get nextVerse;

  String get titleLabel;

  String get leftLabel;

  String get rightLabel;

  Future<bool> init({
    required List<VerseTodayPrg> progresses,
    required int startIndex,
    required Function() update,
    required GameHelper gameHelper,
    required Helper helper,
  });

  void onClose();

  void onTapLeft();

  void onTapMiddle();

  void onTapRight();

  void onLongTapRight();

  Future<void> jump({required int progress, required int nextDayValue});
}
