// entity/segment_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['crn', 'k'], unique: true),
  ],
)
class SegmentKey {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String crn;
  final String k;

  SegmentKey(
    this.crn,
    this.k, {
    this.id,
  });
}
