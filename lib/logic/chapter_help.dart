import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';

class ChapterHelp {
  static List<ChapterShow> cache = [];
  static Map<int, ChapterShow> chapterKeyIdToShow = {};

  static tryGen({force = false}) async {
    if (cache.isEmpty || force) {
      cache = await Db().db.chapterKeyDao.getAllChapter(Classroom.curr);
      chapterKeyIdToShow = {for (var chapter in cache) chapter.chapterKeyId: chapter};
    }
  }

  static Future<List<ChapterShow>> getChapters({force = false}) async {
    await tryGen(force: force);
    return cache;
  }

  static ChapterShow? getCache(int chapterKeyId) {
    return ChapterHelp.chapterKeyIdToShow[chapterKeyId];
  }

  static void deleteCache(int chapterKeyId) {
    cache.removeWhere((element) => element.chapterKeyId == chapterKeyId);
    chapterKeyIdToShow.remove(chapterKeyId);
  }
}
