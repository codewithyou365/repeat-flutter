// entity/kv.dart

import 'package:floor/floor.dart';

enum CrK {
  todayScheduleCreateDate,
  todayScheduleConfig,
  todayScheduleConfigInUse,
  todayFullCustomScheduleConfigCount,
  typeGameForIgnorePunctuation,
  typeGameForIgnoreCase,
  blockItRightGameForEditorUserId,
  blockItRightGameForMaxScore,
  blockItRightGameForIgnorePunctuation,
  blockItRightGameForIgnoreCase,
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
