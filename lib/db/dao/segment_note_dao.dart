import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_note.dart';

@dao
abstract class SegmentNoteDao {
  @Query('SELECT * FROM SegmentNote WHERE segmentKeyId=:segmentKeyId')
  Future<SegmentNote?> getBySegmentKeyId(int segmentKeyId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(SegmentNote segmentNote);
}
