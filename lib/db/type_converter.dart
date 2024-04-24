import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

class KConverter extends TypeConverter<K, String> {
  @override
  K decode(String databaseValue) {
    return K.values.byName(databaseValue);
  }

  @override
  String encode(K value) {
    return value.name;
  }
}

class DateTimeConverter extends TypeConverter<DateTime, int> {
  @override
  DateTime decode(int databaseValue) {
    return DateTime.fromMillisecondsSinceEpoch(databaseValue);
  }

  @override
  int encode(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}

class DateConverter extends TypeConverter<Date, int> {
  @override
  Date decode(int databaseValue) {
    return Date(databaseValue);
  }

  @override
  int encode(Date value) {
    return value.value;
  }
}
