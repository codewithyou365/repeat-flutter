import 'dart:convert' as convert;

import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class ScheduleHelp {
  static Future<bool> addBookToSchedule(int bookId, String url) async {
    Book? book = await Db().db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["book"]));
      return false;
    }
    book.url = url;
    Map<String, dynamic>? jsonData = await DocHelp.toJsonMap(DocPath.getRelativeIndexPath(book.id!));
    if (jsonData == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["jsonData"]));
      return false;
    }
    var kv = BookContent.fromJson(jsonData);
    if (kv.chapter.length >= 100000) {
      Snackbar.show(I18nKey.labelTooMuchData.trArgs(["chapter"]));
      return false;
    }
    for (var d in kv.chapter) {
      if (d.verse.length >= 100000) {
        Snackbar.show(I18nKey.labelTooMuchData.trArgs(["verse"]));
        return false;
      }
    }
    var now = DateTime.now();

    Map<String, dynamic> excludeChapter = {};
    jsonData.forEach((k, v) {
      if (k != 'c') {
        excludeChapter[k] = v;
      }
    });
    book.content = convert.jsonEncode(excludeChapter);
    List<Chapter> chapters = [];
    List<Verse> verses = [];
    List<dynamic> rawChapters = jsonData['c'] as List<dynamic>;
    for (var chapterIndex = 0; chapterIndex < kv.chapter.length; chapterIndex++) {
      Map<String, dynamic> rawChapter = rawChapters[chapterIndex] as Map<String, dynamic>;
      Map<String, dynamic> excludeVerse = {};
      rawChapter.forEach((k, v) {
        if (k != 'v') {
          excludeVerse[k] = v;
        }
      });
      String chapterContent = convert.jsonEncode(excludeVerse);

      var chapter = kv.chapter[chapterIndex];
      chapters.add(Chapter(
        classroomId: book.classroomId,
        bookId: book.id!,
        chapterIndex: chapterIndex,
        content: chapterContent,
        contentVersion: 1,
      ));
      List<dynamic> rawVerses = rawChapter['v'] as List<dynamic>;
      for (var verseIndex = 0; verseIndex < chapter.verse.length; verseIndex++) {
        var rawVerse = rawVerses[verseIndex] as Map<String, dynamic>;
        var verse = chapter.verse[verseIndex];
        Map<String, dynamic> excludeNote = {};
        rawVerse.forEach((k, v) {
          if (k != 'n') {
            excludeNote[k] = v;
          }
        });
        String verseContent = convert.jsonEncode(excludeNote);
        verses.add(Verse(
          classroomId: book.classroomId,
          bookId: book.id!,
          chapterId: 0,
          chapterIndex: chapterIndex,
          verseIndex: verseIndex,

          sort: VerseHelp.toVerseSort(book.sort, chapterIndex, verseIndex),
          content: verseContent,
          contentVersion: 1,
          note: verse.note ?? '',
          noteVersion: 1,
          nextLearnDate: Date.from(now),
          progress: 0,
        ));
      }
    }
    await Db().db.bookDao.import(book, chapters, verses);
    return true;
  }
}
