// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['group', 'key'],
  indices: [
    Index(value: ['sort'], unique: true),
  ],
)
class Segment {
  final String group;
  final String key;
  final int indexDocId;
  final int mediaDocId;

  final int lessonIndex;
  final int segmentIndex;

  final int sort;

  Segment(
    this.key,
    this.indexDocId,
    this.mediaDocId,
    this.lessonIndex,
    this.segmentIndex,
    this.sort, {
    this.group = "en",
  });
}
