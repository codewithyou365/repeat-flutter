import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

import 'model/verse_show.dart';

class QueryLesson {
  final int contentSerial;
  final int? chapterIndex;
  final int? minLessonIndex;

  QueryLesson({
    required this.contentSerial,
    this.chapterIndex,
    this.minLessonIndex,
  });
}

class VerseHelp {
  static List<VerseShow> cache = [];
  static Map<int, VerseShow> verseKeyIdToShow = {};

  static Future<String> getVerseKey(int classroomId) async {
    var progressUpdateTime = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.updateVerseShowTime) ?? '';
    var contentUpdateTime = await Db().db.scheduleDao.getMaxContentUpdateTime(Classroom.curr) ?? 0;
    return '$progressUpdateTime-$contentUpdateTime';
  }

  static tryGen({force = false, QueryLesson? query}) async {
    if (cache.isEmpty || force || query != null) {
      if (query != null) {
        if (query.chapterIndex != null) {
          List<VerseShow> lessonVerse = await Db().db.scheduleDao.getVerseByLessonIndex(Classroom.curr, query.contentSerial, query.chapterIndex!);
          cache.removeWhere((verse) => verse.contentSerial == query.contentSerial && verse.lessonIndex == query.chapterIndex!);
          cache.addAll(lessonVerse);
        } else if (query.minLessonIndex != null) {
          List<VerseShow> lessonVerse = await Db().db.scheduleDao.getVerseByMinLessonIndex(Classroom.curr, query.contentSerial, query.minLessonIndex!);
          cache.removeWhere((verse) => verse.contentSerial == query.contentSerial && verse.lessonIndex >= query.minLessonIndex!);
          cache.addAll(lessonVerse);
        }
        verseKeyIdToShow = {for (var verse in cache) verse.verseKeyId: verse};
      } else {
        cache = await Db().db.scheduleDao.getAllVerse(Classroom.curr);
        verseKeyIdToShow = {for (var verse in cache) verse.verseKeyId: verse};
      }
    }
  }

  static Future<List<VerseShow>> getVerses({force = false, QueryLesson? query}) async {
    await tryGen(force: force, query: query);
    return cache;
  }

  static VerseShow? getCache(int verseKeyId) {
    return VerseHelp.verseKeyIdToShow[verseKeyId];
  }

  static String getVersePos(int verseKeyId) {
    var verse = VerseHelp.verseKeyIdToShow[verseKeyId];
    if (verse != null) {
      return "${verse.toLessonPos()}${verse.toVersePos()}";
    }
    return "";
  }

  static void deleteCache(int verseKeyId) {
    cache.removeWhere((element) => element.verseKeyId == verseKeyId);
    verseKeyIdToShow.remove(verseKeyId);
  }
}
