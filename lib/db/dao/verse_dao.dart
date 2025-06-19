import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse.dart';

@dao
abstract class VerseDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(Verse entity);

  @Query('SELECT * FROM Verse'
      ' WHERE bookId=:bookId AND chapterIndex=:chapterIndex AND verseIndex=:verseIndex')
  Future<Verse?> one(int bookId, int chapterIndex, int verseIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex order by chapterIndex,verseIndex limit 1')
  Future<Verse?> last(int bookId, int minChapterIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE bookId=:bookId AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
  Future<List<Verse>> findByMinVerseIndex(int bookId, int chapterIndex, int minVerseIndex);

  @Query('DELETE FROM Verse'
      ' WHERE bookId=:bookId AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
  Future<void> deleteByMinVerseIndex(int bookId, int chapterIndex, int minVerseIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
  Future<List<Verse>> findByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('DELETE FROM Verse'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('DELETE FROM Verse WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM Verse'
      ' WHERE Verse.bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<Verse> entities);
}
