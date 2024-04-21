// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['sort'], unique: true),
])
class Segment {
  @primaryKey
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
    this.sort,
  );
}
