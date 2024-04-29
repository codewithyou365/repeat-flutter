// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['g', 'k'],
  indices: [
    Index(value: ['sort'], unique: true),
  ],
)
class Segment {
  final String g;
  final String k;
  final int indexDocId;
  final int mediaDocId;

  final int lessonIndex;
  final int segmentIndex;

  final int sort;

  Segment(
    this.k,
    this.indexDocId,
    this.mediaDocId,
    this.lessonIndex,
    this.segmentIndex,
    this.sort, {
    this.g = "en",
  });
}
