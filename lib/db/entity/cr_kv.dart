// entity/kv.dart

import 'package:floor/floor.dart';

enum CrK {
  todayScheduleCreateDate,
  todayScheduleConfig,
  todayScheduleConfigInUse,
  todayFullCustomScheduleConfigCount,
  blockItRightGameForAutoBlank,
  blockItRightGameForEditorUserId,
  blockItRightGameForBlankContentPercent,
  blockItRightGameForMaxScore,
  blockItRightGameForIgnorePunctuation,
  blockItRightGameForIgnoreCase,
  wordSlicerGameForEditorUserId,
  wordSlicerGameForMaxScore,
  wordSlicerGameForHiddenContentPercent,
  inputGameForIgnoringPunctuation,
  inputGameForMatchType,
  inputGameForSkipCharacter,
  // "模版"功能已删，这两个 key 不再写入。但老库里还留着历史行，而 CrKvConverter
  // 是用 CrK.values.byName 反解的，删掉枚举值会让读到这些行的查询直接抛异常，所以保留。
  copyTemplate,
  copyListTemplate,
  lastRecordCreateDate4StatsTotalTime,
  lastRecordCreateDate4StatsTotalLearning,
  statsTotalTime,
  statsTotalLearning,
  lastCache4ProgressStats,
  nextTimeForSettingLearningProgressWarning,
  ttsEngineForTip,
  ttsLanguageIndexForTip,
  ttsVoiceIndexForTip,
  ttsRateIndexForTip,
  ttsPitchIndexForTip,
  ttsEngineForAnswer,
  ttsLanguageIndexForAnswer,
  ttsVoiceIndexForAnswer,
  ttsRateIndexForAnswer,
  ttsPitchIndexForAnswer,
  ttsEngineForQuestion,
  ttsLanguageIndexForQuestion,
  ttsVoiceIndexForQuestion,
  ttsRateIndexForQuestion,
  ttsPitchIndexForQuestion,
  ttsEngineForNote,
  ttsLanguageIndexForNote,
  ttsVoiceIndexForNote,
  ttsRateIndexForNote,
  ttsPitchIndexForNote,
  lastGameIndex,
  classroomResourceVersion,
  assistiveTouchEnabled,
  assistiveTouchPosX,
  assistiveTouchPosY,
  assistiveTouchVisibleBuiltins,
  gamepadEnabled,
  gamepadBindings,
  lastBrowseVerseId,
  quickEntry,
  displayModeBrowse,
  displayModeExamine,
  displayModeGlobalBrowse,
  assistiveTouchSeekBackSeconds,
  searchIndexFingerprint,
  practiceDraft,
  practiceMode,
  practiceIgnoreSpace,
  practiceIgnorePunctuation,
  practiceIgnoreCase,
  practiceIgnoreNumber,

  /// 息屏录音建章的课堂级设置。课堂本身就是语言上下文，所以放 CrK 而不是 K
  /// （模型本体是全设备共享的，那些放 K）。CrK 同样是按 name 存的，只能往后加。
  aiTtsSpeakerId,
  aiRecordScreenMode,
  aiRecordAutoPlay,

  /// 快速进入选了「录音翻译生成」时，进哪本书：第一本 / 最后一本 / 每次自己选。
  /// 存的是 RecordBookPick 的 name，见 [QuickEntry.getBookPick]。
  aiRecordBookPick,
}

@Entity(primaryKeys: ['classroomId', 'k'])
class CrKv {
  final int classroomId;
  final CrK k;
  final String value;

  CrKv(
    this.classroomId,
    this.k,
    this.value,
  );
}
