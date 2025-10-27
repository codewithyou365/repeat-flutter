import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';

class ChapterHelp {
  static List<ChapterShow> cache = [];
  static Map<int, ChapterShow> chapterIdToShow = {};
  static Map<String, ChapterShow> bookIdAndChapterIndexToShow = {};

  static tryGen({force = false}) async {
    if (cache.isEmpty || force) {
      cache = await Db().db.chapterDao.getAllChapter(Classroom.curr);
      chapterIdToShow = {for (var chapter in cache) chapter.chapterId: chapter};
      bookIdAndChapterIndexToShow = {for (var chapter in cache) '${chapter.bookId}_${chapter.chapterIndex}': chapter};
    }
  }

  static Future<List<ChapterShow>> getChapters({force = false}) async {
    await tryGen(force: force);
    return cache;
  }

  static ChapterShow? getCache(int chapterId) {
    return ChapterHelp.chapterIdToShow[chapterId];
  }

  static ChapterShow? getCacheByIndex(int bookId, int chapterIndex) {
    return bookIdAndChapterIndexToShow['${bookId}_$chapterIndex'];
  }

  static void deleteCache(int chapterId) {
    cache.removeWhere((element) => element.chapterId == chapterId);
    chapterIdToShow.remove(chapterId);
  }
}
