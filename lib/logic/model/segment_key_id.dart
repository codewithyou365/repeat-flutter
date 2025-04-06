import 'package:floor/floor.dart';

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
