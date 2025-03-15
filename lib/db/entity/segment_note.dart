// entity/segment_note.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['segmentHash'],
)
class SegmentNote {
  final int classroomId;
  final String segmentHash;

  final String note;

  SegmentNote(
    this.classroomId,
    this.segmentHash,
    this.note,
  );
}
