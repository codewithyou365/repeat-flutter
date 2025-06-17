import 'package:floor/floor.dart';

@dao
abstract class VerseReviewDao {
  @Query('DELETE FROM VerseReview WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);
}
