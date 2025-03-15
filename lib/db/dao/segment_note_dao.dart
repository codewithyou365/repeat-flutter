import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_note.dart';

@dao
abstract class SegmentNoteDao {
  @Query('SELECT * FROM SegmentNote WHERE classroomId=:classroomId AND segmentHash=:segmentHash')
  Future<SegmentNote?> getBySegmentHash(int classroomId, String segmentHash);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(SegmentNote segmentNote);
}
