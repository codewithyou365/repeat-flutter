// entity/segment_note.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['segmentKeyId'],
)
class SegmentNote {
  int segmentKeyId;

  final String note;

  SegmentNote(
    this.segmentKeyId,
    this.note,
  );
}
