// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['crn', 'k'],
  indices: [
    Index(value: ['sort'], unique: true),
  ],
)
class Segment {
  final String crn;
  final String k;
  final int indexDocId;
  final int mediaDocId;

  final int lessonIndex;
  final int segmentIndex;

  final int sort;

  Segment(
    this.crn,
    this.k,
    this.indexDocId,
    this.mediaDocId,
    this.lessonIndex,
    this.segmentIndex,
    this.sort,
  );
}
