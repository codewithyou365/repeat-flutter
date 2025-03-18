import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

@Entity(tableName: "")
class SegmentKeyId {
  @primaryKey
  final int id;
  final String key;

  SegmentKeyId(
    this.id,
    this.key,
  );
}
