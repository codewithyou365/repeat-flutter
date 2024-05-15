// entity/kv.dart

import 'package:floor/floor.dart';

enum CrK {
  todayLearnCreateDate,
  todayLearnScheduleConfig,
}

@Entity(primaryKeys: ['crn', 'k'])
class CrKv {
  final String crn;
  final CrK k;
  final String value;

  CrKv(
    this.crn,
    this.k,
    this.value,
  );
}
