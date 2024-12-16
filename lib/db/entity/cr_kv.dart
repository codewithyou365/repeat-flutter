// entity/kv.dart

import 'package:floor/floor.dart';

enum CrK {
  todayScheduleCreateDate,
  todayScheduleConfig,
  todayScheduleConfigInUse,
  todayFullCustomScheduleConfigCount,
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
