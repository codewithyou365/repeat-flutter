// entity/segment.dart

import 'package:floor/floor.dart';

@entity
class Segment {
  @primaryKey
  final String key;
  final int indexDocId;
  final int mediaDocId;

  final int lessonIndex;
  final int segmentIndex;

  Segment(
    this.key,
    this.indexDocId,
    this.mediaDocId,
    this.lessonIndex,
    this.segmentIndex,
  );
}
