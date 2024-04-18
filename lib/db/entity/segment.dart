// entity/segment.dart

import 'package:floor/floor.dart';

@entity
class Segment {
  @primaryKey
  final String key;
  final int indexFileId;
  final int mediaFileId;

  final int lessonIndex;
  final int segmentIndex;

  Segment(
    this.key,
    this.indexFileId,
    this.mediaFileId,
    this.lessonIndex,
    this.segmentIndex,
  );
}
