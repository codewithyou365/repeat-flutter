import 'dart:convert' as convert;

import 'package:get/get.dart';
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

class ImportHelp {
  static Future<bool> import(int bookId, String url) async {
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
        String verseContent = convert.jsonEncode(rawVerse);
        verses.add(Verse(
          classroomId: book.classroomId,
          bookId: book.id!,
          chapterId: 0,
          chapterIndex: chapterIndex,
          verseIndex: verseIndex,
          sort: VerseHelp.toVerseSort(book.sort, chapterIndex, verseIndex),
          content: verseContent,
          contentVersion: 1,
          learnDate: Date.from(now),
          progress: 0,
        ));
      }
    }
    await Db().db.bookDao.import(book, chapters, verses);
    return true;
  }

  static Future<bool> reimport(int bookId, Map<String, dynamic>? jsonData) async {
    if (jsonData == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["jsonData"]));
      return false;
    }
    Book? book = await Db().db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["book"]));
      return false;
    }

    var kv = BookContent.fromJson(jsonData);
    if (kv.chapter.length >= 100000) {
      Snackbar.showAndThrow(I18nKey.labelTooMuchData.trArgs(["chapter"]));
      return false;
    }
    for (var d in kv.chapter) {
      if (d.verse.length >= 100000) {
        Snackbar.showAndThrow(I18nKey.labelTooMuchData.trArgs(["verse"]));
        return false;
      }
    }
    var now = DateTime.now();

    Map<String, dynamic> bookContent = {};
    jsonData.forEach((k, v) {
      if (k != 'c') {
        bookContent[k] = v;
      }
    });
    book.content = convert.jsonEncode(bookContent);

    List<Chapter> insertChapters = [];
    List<Chapter> updateChapters = [];
    List<Verse> insertVerses = [];
    List<Verse> updateVerses = [];

    List<dynamic> rawChapters = jsonData['c'] as List<dynamic>;
    for (var chapterIndex = 0; chapterIndex < kv.chapter.length; chapterIndex++) {
      Map<String, dynamic> rawChapter = rawChapters[chapterIndex] as Map<String, dynamic>;

      Map<String, dynamic> chapterContent = {};
      rawChapter.forEach((k, v) {
        if (k != 'v') {
          chapterContent[k] = v;
        }
      });

      var chapter = kv.chapter[chapterIndex];

      Chapter chapterEntity = Chapter(
        id: chapter.id,
        classroomId: book.classroomId,
        bookId: book.id!,
        chapterIndex: chapterIndex,
        content: convert.jsonEncode(chapterContent),
        contentVersion: 0,
      );

      if (chapterEntity.id == null) {
        insertChapters.add(chapterEntity);
      } else {
        updateChapters.add(chapterEntity);
      }

      // Process verses
      List<dynamic> rawVerses = rawChapter['v'] as List<dynamic>;

      for (var verseIndex = 0; verseIndex < chapter.verse.length; verseIndex++) {
        var verse = chapter.verse[verseIndex];
        var rawVerse = rawVerses[verseIndex] as Map<String, dynamic>;
        String verseContent = convert.jsonEncode(rawVerse);
        var learnDate = Date.from(now);
        if (verse.learnDate != null) {
          learnDate = Date(verse.learnDate!);
        }
        Verse verseEntity = Verse(
          id: verse.id,
          classroomId: book.classroomId,
          bookId: book.id!,
          chapterId: chapterEntity.id ?? 0,
          chapterIndex: chapterIndex,
          verseIndex: verseIndex,
          sort: VerseHelp.toVerseSort(book.sort, chapterIndex, verseIndex),
          content: verseContent,
          contentVersion: 1,
          learnDate: learnDate,
          progress: verse.progress ?? 0,
        );

        if (verseEntity.id == null) {
          insertVerses.add(verseEntity);
        } else {
          updateVerses.add(verseEntity);
        }
      }
    }
    List<int> chaptersIds = updateChapters.map((c) => c.id!).toList();
    var updateChapterCount = await Db().db.chapterDao.countByIds(chaptersIds);
    if (updateChapterCount == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomalyWithArg.trArgs(["updateChapterCount is null"]));
      return false;
    }
    if (updateChapterCount != updateChapters.length) {
      Snackbar.showAndThrow(I18nKey.pleaseDontModifyId.tr);
      return false;
    }

    List<int> versesIds = updateVerses.map((c) => c.id!).toList();
    var updateVerseCount = await Db().db.verseDao.countByIds(versesIds);
    if (updateVerseCount == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomalyWithArg.trArgs(["updateVerseCount is null"]));
      return false;
    }
    if (updateVerseCount != updateVerses.length) {
      Snackbar.showAndThrow(I18nKey.pleaseDontModifyId.tr);
      return false;
    }

    await Db().db.bookDao.reimport(
          book,
          insertChapters,
          updateChapters,
          insertVerses,
          updateVerses,
        );

    return true;
  }
}
