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
