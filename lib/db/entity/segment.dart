// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['segmentKeyId'],
  indices: [
    Index(value: ['sort']),
  ],
)
class Segment {
  int segmentKeyId;
  final int indexDocId;
  final int mediaDocId;

  final int lessonIndex;
  final int segmentIndex;

  final int sort;

  Segment(
    this.segmentKeyId,
    this.indexDocId,
    this.mediaDocId,
    this.lessonIndex,
    this.segmentIndex,
    this.sort,
  );
}
