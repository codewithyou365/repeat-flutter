import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

import 'model/verse_show.dart';

class QueryChapter {
  final int bookId;
  final int? chapterIndex;
  final int? minChapterIndex;

  QueryChapter({
    required this.bookId,
    this.chapterIndex,
    this.minChapterIndex,
  });
}

class VerseHelp {
  static List<VerseShow> cache = [];
  static Map<int, VerseShow> verseKeyIdToShow = {};

  static Future<String> getVerseKey(int classroomId) async {
    var progressUpdateTime = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.updateVerseShowTime) ?? '';
    var contentUpdateTime = await Db().db.scheduleDao.getMaxBookUpdateTime(Classroom.curr) ?? 0;
    return '$progressUpdateTime-$contentUpdateTime';
  }

  static tryGen({force = false, QueryChapter? query}) async {
    if (cache.isEmpty || force || query != null) {
      if (query != null) {
        if (query.chapterIndex != null) {
          List<VerseShow> chapterVerse = await Db().db.scheduleDao.getVerseByChapterIndex(query.bookId, query.chapterIndex!);
          cache.removeWhere((verse) => verse.bookId == query.bookId && verse.chapterIndex == query.chapterIndex!);
          cache.addAll(chapterVerse);
        } else if (query.minChapterIndex != null) {
          List<VerseShow> chapterVerse = await Db().db.scheduleDao.getVerseByMinChapterIndex(query.bookId, query.minChapterIndex!);
          cache.removeWhere((verse) => verse.bookId == query.bookId && verse.chapterIndex >= query.minChapterIndex!);
          cache.addAll(chapterVerse);
        }
        verseKeyIdToShow = {for (var verse in cache) verse.verseKeyId: verse};
      } else {
        cache = await Db().db.scheduleDao.getAllVerse(Classroom.curr);
        verseKeyIdToShow = {for (var verse in cache) verse.verseKeyId: verse};
      }
    }
  }

  static Future<List<VerseShow>> getVerses({force = false, QueryChapter? query}) async {
    await tryGen(force: force, query: query);
    return cache;
  }

  static VerseShow? getCache(int verseKeyId) {
    return VerseHelp.verseKeyIdToShow[verseKeyId];
  }

  static String getVersePos(int verseKeyId) {
    var verse = VerseHelp.verseKeyIdToShow[verseKeyId];
    if (verse != null) {
      return "${verse.toChapterPos()}${verse.toVersePos()}";
    }
    return "";
  }

  static void deleteCache(int verseKeyId) {
    cache.removeWhere((element) => element.verseKeyId == verseKeyId);
    verseKeyIdToShow.remove(verseKeyId);
  }
}
