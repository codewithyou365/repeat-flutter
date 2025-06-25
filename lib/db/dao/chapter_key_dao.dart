// // dao/chapter_key_dao.dart
//
// import 'dart:convert' as convert;
//
// import 'package:floor/floor.dart';
// import 'package:repeat_flutter/db/database.dart';
// import 'package:repeat_flutter/db/entity/book.dart' show Book;
// import 'package:repeat_flutter/db/entity/chapter.dart';
// import 'package:repeat_flutter/db/entity/chapter_content_version.dart';
// import 'package:repeat_flutter/db/entity/classroom.dart';
// import 'package:repeat_flutter/db/entity/verse.dart';
// import 'package:repeat_flutter/db/entity/content_version.dart';
// import 'package:repeat_flutter/i18n/i18n_key.dart';
// import 'package:repeat_flutter/logic/model/chapter_show.dart';
// import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
//
// @dao
// abstract class ChapterKeyDao {
//   late AppDatabase db;
//
//   @Query('SELECT *'
//       ' FROM ChapterKey'
//       ' WHERE ChapterKey.id=:id')
//   Future<ChapterKey?> getById(int id);
//
//   @Query('SELECT id'
//       ' FROM ChapterKey'
//       ' WHERE bookId=:bookId and chapterIndex=:chapterIndex and version=:version')
//   Future<int?> getChapterKeyId(int bookId, int chapterIndex, int version);
//
//   @Query('SELECT ifnull(sum(Chapter.chapterId is null),0) missingCount'
//       ' FROM ChapterKey'
//       ' JOIN Book ON Book.id=:bookId AND Book.docId!=0'
//       ' LEFT JOIN Chapter ON Chapter.chapterId=ChapterKey.id')
//   Future<int?> getMissingCount(int bookId);
//
//   @Query('SELECT ChapterKey.id chapterId'
//       ',Book.id bookId'
//       ',Book.name bookName'
//       ',Book.sort bookSort'
//       ',ChapterKey.content chapterContent'
//       ',ChapterKey.contentVersion chapterContentVersion'
//       ',ChapterKey.chapterIndex'
//       ',Chapter.chapterId is null missing'
//       ' FROM ChapterKey'
//       " JOIN Book ON Book.id=ChapterKey.bookId AND Book.docId!=0"
//       ' LEFT JOIN Chapter ON Chapter.chapterId=ChapterKey.id'
//       ' WHERE ChapterKey.classroomId=:classroomId')
//   Future<List<ChapterShow>> getAllChapter(int classroomId);
//
//   @Query('SELECT * FROM ChapterKey'
//       ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
//   Future<List<ChapterKey>> findByMinChapterIndex(int bookId, int minChapterIndex);
//
//   @Query('DELETE FROM ChapterKey'
//       ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
//   Future<void> deleteByMinChapterIndex(int bookId, int minChapterIndex);
//
//   @Query('DELETE FROM ChapterKey'
//       ' WHERE classroomId=:classroomId')
//   Future<void> deleteByClassroomId(int classroomId);
//
//   @Query('UPDATE ChapterKey set content=:content,contentVersion=:contentVersion WHERE id=:id')
//   Future<void> updateKeyAndContent(int id, String content, int contentVersion);
//
//   @Query('SELECT * FROM ChapterKey WHERE bookId=:bookId')
//   Future<List<ChapterKey>> findByBook(int bookId);
//
//   @Query('SELECT * FROM ChapterKey WHERE bookId=:bookId and version=:version')
//   Future<List<ChapterKey>> findByBookAndVersion(int bookId, int version);
//
//   @Query('DELETE FROM ChapterKey WHERE id=:id')
//   Future<void> deleteById(int id);
//
//   @Insert(onConflict: OnConflictStrategy.fail)
//   Future<void> insertOrFail(List<ChapterKey> entities);
//
//   @Update(onConflict: OnConflictStrategy.fail)
//   Future<void> updateOrFail(List<ChapterKey> entities);
//
//   Future<bool> import(List<Chapter> newChapters, List<ChapterKey> newChapterKeys, int bookId) async {
//     List<ChapterKey> oldChapters = await findByBook(bookId);
//     var maxVersion = 0;
//     Map<String, ChapterKey> keyToChapter = {};
//     Map<String, int> keyToId = {};
//     for (var oldChapter in oldChapters) {
//       if (oldChapter.version > maxVersion) {
//         maxVersion = oldChapter.version;
//       }
//       keyToChapter[oldChapter.k] = oldChapter;
//       keyToId[oldChapter.k] = oldChapter.id!;
//     }
//     var nextVersion = maxVersion + 1;
//     Map<int, ChapterKey> needToModifyMap = {};
//     List<ChapterKey> needToInsert = [];
//     for (var newChapter in newChapterKeys) {
//       newChapter.version = nextVersion;
//       ChapterKey? oldChapter = keyToChapter[newChapter.k];
//       if (oldChapter == null) {
//         needToInsert.add(newChapter);
//       } else {
//         newChapter.id = oldChapter.id;
//         newChapter.contentVersion = oldChapter.contentVersion;
//         if (oldChapter.content != newChapter.content) {
//           needToModifyMap[oldChapter.id!] = newChapter;
//         }
//       }
//     }
//     if (needToInsert.isNotEmpty) {
//       await insertOrFail(needToInsert);
//       newChapterKeys.clear();
//       newChapterKeys.addAll(await findByBookAndVersion(bookId, nextVersion));
//       newChapterKeys.addAll(needToModifyMap.values);
//       newChapterKeys.sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));
//       keyToId = {for (var chapterKey in newChapterKeys) chapterKey.k: chapterKey.id!};
//     }
//
//     List<ChapterContentVersion> needToInsertChapterContentVersion = await db.chapterContentVersionDao.import(newChapterKeys, bookId);
//     Map<int, ChapterContentVersion> newIdToChapterVersion = {for (var v in needToInsertChapterContentVersion) v.chapterId: v};
//     for (var i = 0; i < newChapterKeys.length; i++) {
//       ChapterKey newChapter = newChapterKeys[i];
//       var id = keyToId[newChapter.k]!;
//       var contentVersion = newIdToChapterVersion[id];
//       if (contentVersion != null && newChapter.contentVersion != contentVersion.version) {
//         newChapter.contentVersion = contentVersion.version;
//         needToModifyMap[newChapter.id!] = newChapter;
//       }
//       newChapters[i].chapterId = id;
//     }
//
//     await db.chapterDao.deleteByBookId(bookId);
//     if (newChapters.isNotEmpty) {
//       await db.chapterDao.updateOrFail(newChapters);
//     }
//     if (needToModifyMap.isNotEmpty) {
//       await updateOrFail(needToModifyMap.values.toList());
//     }
//     return newChapterKeys.length < keyToId.length;
//   }
//
//
//
// }
