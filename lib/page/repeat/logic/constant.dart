import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

enum MediaType {
  audio(allowedExtensions: ['mp3', 'wav', 'mp4', 'mov']),
  video(allowedExtensions: ['mp4', 'mov']),
  image(allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif']),

  /// content 数组里的网页项。单个 html 是自包含的富文本（公式、表格），
  /// zip 是带库带模型带贴图的整包（3D 场景基本都得走这个），入口是里面的 index.html。
  ///
  /// **别把这几个扩展名加进 ChapterImportHelp.showTypeForExtension**：那个返回的是
  /// RepeatViewEnum 的名字，多返回一个认不出的视图类型会让整页取不到视图直接白屏。
  /// 网页是内容项的一种形态，跟"这一节用哪种视图"是两回事。
  web(allowedExtensions: ['html', 'htm', 'zip']);

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

/// The 3 entries that can launch the repeat page with a display mode
/// ([ShowMode]) the user is allowed to remember per classroom: 学习浏览,
/// 学习考查, 全局浏览.
enum DisplayModeSource {
  browse(k: CrK.displayModeBrowse, fallback: ShowMode.openBook),
  examine(k: CrK.displayModeExamine, fallback: ShowMode.closedBook),
  globalBrowse(k: CrK.displayModeGlobalBrowse, fallback: ShowMode.edit);

  const DisplayModeSource({required this.k, required this.fallback});

  final CrK k;
  final ShowMode fallback;
}

class DisplayModeKv {
  static Future<ShowMode> get(int classroomId, DisplayModeSource source) async {
    var value = await Db().db.crKvDao.getStr(classroomId, source.k);
    if (value == null || value.isEmpty) {
      return source.fallback;
    }
    return ShowMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => source.fallback,
    );
  }

  static Future<void> set(int classroomId, DisplayModeSource source, ShowMode mode) async {
    await Db().db.crKvDao.insertOrReplace(CrKv(classroomId, source.k, mode.name));
  }
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
