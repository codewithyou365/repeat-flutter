import 'package:floor/floor.dart';

@Entity(tableName: "")
class SegmentKeyId {
  @primaryKey
  final int id;
  final String k;

  SegmentKeyId(
    this.id,
    this.k,
  );
}
