import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'game_helper.dart';

import 'constant.dart';

abstract class RepeatLogic {
  late Function() update;

  late GameHelper gameHelper;

  RepeatStep step = RepeatStep.recall;

  TipLevel tip = TipLevel.none;

  VerseTodayPrg? get currVerse;

  VerseTodayPrg? get nextVerse;

  String get titleLabel;

  String get leftLabel;

  String get rightLabel;

  Future<bool> init(
    List<VerseTodayPrg> all,
    Function() update,
    GameHelper gameHelper,
  );

  void onClose();

  void onTapLeft();

  void onTapMiddle();

  void onTapRight();

  Function()? getLongTapRight() {
    return null;
  }

  Future<void> jump({required int progress, required int nextDayValue});
}
