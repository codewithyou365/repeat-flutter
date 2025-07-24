import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse_stats.dart';
import 'package:repeat_flutter/db/entity/time_stats.dart';

@dao
abstract class GameUserInputDao {
  @Query('DELETE FROM GameUserInput WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM GameUserInput WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM GameUserInput WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  @Query('DELETE FROM GameUserInput WHERE chapterId in (:chapterIds)')
  Future<void> deleteByChapterIds(List<int> chapterIds);

  @Query('DELETE FROM GameUserInput WHERE verseId=:verseId')
  Future<void> deleteByVerseId(int verseId);
}
