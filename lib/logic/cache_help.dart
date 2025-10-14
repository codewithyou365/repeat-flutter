import 'package:repeat_flutter/logic/model/verse_show.dart';

import 'book_help.dart';
import 'chapter_help.dart';
import 'verse_help.dart';

class CacheHelp {
  static Future<void> refreshBook() async {
    await BookHelp.tryGen(force: true);
  }

  static Future<void> refreshAll() async {
    await BookHelp.tryGen(force: true);
    await ChapterHelp.tryGen(force: true);
    await VerseHelp.tryGen(force: true);
  }

  static Future<void> refreshChapterAndVerse() async {
    await ChapterHelp.tryGen(force: true);
    await VerseHelp.tryGen(force: true);
  }

  static Future<List<VerseShow>> refreshVerse({QueryChapter? query}) async {
    return await VerseHelp.getVerses(force: true, query: query);
  }
}
