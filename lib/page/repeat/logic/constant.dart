import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

enum MediaType {
  audio(allowedExtensions: ['mp3', 'wav', 'mp4', 'mov']),
  video(allowedExtensions: ['mp4', 'mov']);

  const MediaType({
    required this.allowedExtensions,
  });

  final List<String> allowedExtensions;
}

enum ShowMode {
  closedBook(i18n: I18nKey.closedBook),
  openBook(i18n: I18nKey.openBook),
  edit(i18n: I18nKey.edit);

  const ShowMode({required this.i18n});

  final I18nKey i18n;
}

enum RepeatStep { recall, evaluate, finish }

enum TipLevel { none, tip }

class TtsKeys {
  final CrK engine;
  final CrK languageIndex;
  final CrK voiceIndex;
  final CrK rateIndex;
  final CrK pitchIndex;

  const TtsKeys({
    required this.engine,
    required this.languageIndex,
    required this.voiceIndex,
    required this.rateIndex,
    required this.pitchIndex,
  });

  static const tip = TtsKeys(
    engine: CrK.ttsEngineForTip,
    languageIndex: CrK.ttsLanguageIndexForTip,
    voiceIndex: CrK.ttsVoiceIndexForTip,
    rateIndex: CrK.ttsRateIndexForTip,
    pitchIndex: CrK.ttsPitchIndexForTip,
  );

  static const answer = TtsKeys(
    engine: CrK.ttsEngineForAnswer,
    languageIndex: CrK.ttsLanguageIndexForAnswer,
    voiceIndex: CrK.ttsVoiceIndexForAnswer,
    rateIndex: CrK.ttsRateIndexForAnswer,
    pitchIndex: CrK.ttsPitchIndexForAnswer,
  );

  static const question = TtsKeys(
    engine: CrK.ttsEngineForQuestion,
    languageIndex: CrK.ttsLanguageIndexForQuestion,
    voiceIndex: CrK.ttsVoiceIndexForQuestion,
    rateIndex: CrK.ttsRateIndexForQuestion,
    pitchIndex: CrK.ttsPitchIndexForQuestion,
  );

  static const note = TtsKeys(
    engine: CrK.ttsEngineForNote,
    languageIndex: CrK.ttsLanguageIndexForNote,
    voiceIndex: CrK.ttsVoiceIndexForNote,
    rateIndex: CrK.ttsRateIndexForNote,
    pitchIndex: CrK.ttsPitchIndexForNote,
  );
}

enum QaType {
  question(acronym: 'q', i18n: I18nKey.question, ttsKeys: TtsKeys.question),
  tip(acronym: 't', i18n: I18nKey.labelTips, ttsKeys: TtsKeys.tip),
  answer(acronym: 'a', i18n: I18nKey.answer, ttsKeys: TtsKeys.answer),
  note(acronym: 'n', i18n: I18nKey.labelNote, ttsKeys: TtsKeys.note);

  final String acronym;

  final I18nKey i18n;
  final TtsKeys ttsKeys;

  const QaType({
    required this.acronym,
    required this.i18n,
    required this.ttsKeys,
  });

  static QaType? fromAcronym(String acronym) {
    for (var value in QaType.values) {
      if (value.acronym == acronym.toLowerCase()) return value;
    }
    return null;
  }
}
