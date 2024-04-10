// entity/schedule.dart

import 'package:floor/floor.dart';

@entity
class ScheduleCurrent {
  @primaryKey
  final String key;

  final String url;
  final int sort;

  final int progress;

  ScheduleCurrent(this.key, this.url, this.sort, this.progress);

  static List<ScheduleCurrent> create(List<String> keys) {
    List<ScheduleCurrent> ret = [];
    for (int i = 0; i < keys.length; i++) {
      ret.add(ScheduleCurrent(keys[i], '', 0, 0));
    }
    return ret;
  }
}
