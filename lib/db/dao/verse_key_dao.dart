// import 'package:floor/floor.dart';
// import 'package:repeat_flutter/db/entity/verse.dart';
// import 'package:repeat_flutter/db/entity/verse_key.dart';
//
// @dao
// abstract class VerseKeyDao {
//   @Insert(onConflict: OnConflictStrategy.fail)
//   Future<void> insertOrFail(VerseKey entity);
//
//   @Query('SELECT * FROM VerseKey where id=:id')
//   Future<VerseKey?> oneById(int id);
//
//   @Query('SELECT count(id) FROM VerseKey where chapterId=:chapterId')
//   Future<int?> count(int chapterId);
//
//   @Query('SELECT * FROM VerseKey'
//       ' WHERE bookId=:bookId AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
//   Future<List<VerseKey>> findByMinVerseIndex(int bookId, int chapterIndex, int minVerseIndex);
//
//   @Query('DELETE FROM VerseKey'
//       ' WHERE bookId=:bookId AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
//   Future<void> deleteByMinVerseIndex(int bookId, int chapterIndex, int minVerseIndex);
//
//   @Query('SELECT * FROM VerseKey'
//       ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
//   Future<List<VerseKey>> findByMinChapterIndex(int bookId, int minChapterIndex);
//
//   @Query('DELETE FROM VerseKey'
//       ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
//   Future<void> deleteByMinChapterIndex(int bookId, int minChapterIndex);
//
//   @Query('DELETE FROM VerseKey WHERE classroomId=:classroomId')
//   Future<void> deleteByClassroomId(int classroomId);
//
//   @Query('DELETE FROM VerseKey WHERE chapterId=:chapterId')
//   Future<void> deleteByChapterKeyId(int chapterId);
//
//   @Insert(onConflict: OnConflictStrategy.fail)
//   Future<void> insertListOrFail(List<VerseKey> entities);
// }
