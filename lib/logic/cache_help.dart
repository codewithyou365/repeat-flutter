import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';

import 'book_help.dart';
import 'chapter_help.dart';
import 'verse_help.dart';

class CacheHelp {
  static Map<int, int> bookId2CacheVersion = {};

  static void incCacheVersion(int bookId) {
    bookId2CacheVersion[bookId] = (bookId2CacheVersion[bookId] ?? 0) + 1;
  }

  static int getCacheVersion(int bookId) {
    return bookId2CacheVersion[bookId] ?? 0;
  }

  static void updateBookContent(Book book) {
    var cache = BookHelp.getCache(book.id!);
    cache?.bookContent = book.content;
    cache?.bookContentVersion = book.contentVersion;
  }

  static void updateChapterContent(Chapter chapter) {
    var cache = ChapterHelp.getCache(chapter.id!);
    cache?.chapterContent = chapter.content;
    cache?.chapterContentVersion = chapter.contentVersion;
  }

  static void updateVerseContent(Verse verse) {
    var cache = VerseHelp.getCache(verse.id!);
    cache?.verseContent = verse.content;
    cache?.verseContentVersion = verse.contentVersion;
  }

  static void updateVerseProgress(Verse verse) {
    var cache = VerseHelp.getCache(verse.id!);
    cache?.progress = verse.progress;
    if (verse.learnDate.value != 0) {
      cache?.learnDate = verse.learnDate;
    }
  }

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
