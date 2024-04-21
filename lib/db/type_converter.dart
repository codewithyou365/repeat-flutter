import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

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
