import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';

class LessonHelp {
  static List<LessonShow> cache = [];
  static Map<int, LessonShow> lessonKeyIdToShow = {};

  static tryGen({force = false}) async {
    if (cache.isEmpty || force) {
      cache = await Db().db.lessonKeyDao.getAllLesson(Classroom.curr);
      lessonKeyIdToShow = {for (var lesson in cache) lesson.lessonKeyId: lesson};
    }
  }

  static Future<List<LessonShow>> getLessons({force = false}) async {
    await tryGen(force: force);
    return cache;
  }

  static LessonShow? getCache(int lessonKeyId) {
    return LessonHelp.lessonKeyIdToShow[lessonKeyId];
  }

  static void deleteCache(int lessonKeyId) {
    cache.removeWhere((element) => element.lessonKeyId == lessonKeyId);
    lessonKeyIdToShow.remove(lessonKeyId);
  }
}
