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
