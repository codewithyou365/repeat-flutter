import 'package:repeat_flutter/i18n/i18n_key.dart';

enum RepeatStep { recall, evaluate, finish }

enum TipLevel { none, tip1, tip2 }

enum QaType {
  answer(acronym: 'a', i18n: I18nKey.labelAnswer),
  question(acronym: 'q', i18n: I18nKey.labelQuestion);

  final String acronym;

  final I18nKey i18n;

  const QaType({required this.acronym, required this.i18n});
}
