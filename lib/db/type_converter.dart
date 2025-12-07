import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
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

class VersionReasonConverter extends TypeConverter<VersionReason, int> {
  @override
  VersionReason decode(int databaseValue) {
    return VersionReason.values[databaseValue];
  }

  @override
  int encode(VersionReason value) {
    return value.index;
  }
}

class CrKConverter extends TypeConverter<CrK, String> {
  @override
  CrK decode(String databaseValue) {
    return CrK.values.byName(databaseValue);
  }

  @override
  String encode(CrK value) {
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

class GameTypeConverter extends TypeConverter<GameType, int> {
  @override
  GameType decode(int index) {
    return GameType.values[index];
  }

  @override
  int encode(GameType value) {
    return value.index;
  }
}
