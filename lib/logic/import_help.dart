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

class ImportHelp {
  static void fixDownloadInfo(Map<String, dynamic> json) {
    if (json['d'] != null) {
      List<DownloadContent> list = DownloadContent.toList(json['d']) ?? [];
      for (DownloadContent v in list) {
        v.url = ".${v.extension}";
      }
      json['d'] = list;
    }
  }

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

    Map<String, dynamic> bookContent = {};
    jsonData.forEach((k, v) {
      if (k != 'c') {
        bookContent[k] = v;
      }
    });
    fixDownloadInfo(bookContent);
    book.content = convert.jsonEncode(bookContent);
    List<Chapter> chapters = [];
    List<Verse> verses = [];
    List<dynamic> rawChapters = jsonData['c'] as List<dynamic>;
    for (var chapterIndex = 0; chapterIndex < kv.chapter.length; chapterIndex++) {
      Map<String, dynamic> rawChapter = rawChapters[chapterIndex] as Map<String, dynamic>;
      Map<String, dynamic> chapterContent = {};
      rawChapter.forEach((k, v) {
        if (k != 'v' && k != 'i') {
          chapterContent[k] = v;
        }
      });
      fixDownloadInfo(chapterContent);

      var chapter = kv.chapter[chapterIndex];
      chapters.add(
        Chapter(
          classroomId: book.classroomId,
          bookId: book.id!,
          chapterIndex: chapterIndex,
          content: convert.jsonEncode(chapterContent),
          contentVersion: 1,
        ),
      );
      List<dynamic> rawVerses = rawChapter['v'] as List<dynamic>;
      for (var verseIndex = 0; verseIndex < chapter.verse.length; verseIndex++) {
        var rawVerse = rawVerses[verseIndex] as Map<String, dynamic>;
        Map<String, dynamic> verseContent = {};
        rawVerse.forEach((k, v) {
          if (k != 'i' && k != 'l' && k != 'p') {
            verseContent[k] = v;
          }
        });
        fixDownloadInfo(verseContent);
        verses.add(
          Verse(
            classroomId: book.classroomId,
            bookId: book.id!,
            chapterId: 0,
            chapterIndex: chapterIndex,
            verseIndex: verseIndex,
            sort: VerseHelp.toVerseSort(book.sort, chapterIndex, verseIndex),
            content: convert.jsonEncode(verseContent),
            contentVersion: 1,
            learnDate: Date.from(now),
            progress: 0,
          ),
        );
      }
    }
    await Db().db.bookDao.import(book, chapters, verses);
    return true;
  }
}
