import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'session_coordinator.dart';

import 'constant.dart';
import 'helper.dart';

abstract class RepeatFlow {
  late Function() update;

  late SessionCoordinator gameHelper;
  late Helper helper;

  RepeatStep step = RepeatStep.recall;

  VerseTodayPrg? get currVerse;

  VerseTodayPrg? get nextVerse;

  String get titleLabel;

  String get leftLabel;

  String get rightLabel;

  Future<bool> init({
    required List<VerseTodayPrg> progresses,
    required int startIndex,
    required Function() update,
    required SessionCoordinator gameHelper,
    required Helper helper,
  });

  void refresh();

  void onClose();

  void onNext();

  void onTapLeft();

  void onTapRight();

  void onLongTapRight();

  Future<void> jump({required int progress, required int nextDayValue});
}
