import 'package:repeat_flutter/i18n/i18n_key.dart';

enum ShowMode {
  closedBook(i18n: I18nKey.closedBook),
  openBook(i18n: I18nKey.openBook),
  edit(i18n: I18nKey.edit);

  const ShowMode({required this.i18n});

  final I18nKey i18n;
}

enum RepeatStep { recall, evaluate, finish }

enum TipLevel { none, tip }

enum QaType {
  question(acronym: 'q', i18n: I18nKey.labelQuestion),
  tip(acronym: 't', i18n: I18nKey.labelTips),
  answer(acronym: 'a', i18n: I18nKey.labelAnswer);

  final String acronym;

  final I18nKey i18n;

  const QaType({required this.acronym, required this.i18n});
}
