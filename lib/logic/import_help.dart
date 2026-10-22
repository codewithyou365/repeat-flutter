import 'dart:convert' as convert;

import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';
import 'package:repeat_flutter/logic/model/verse_brief.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class ImportHelp {
  static void fixDownloadInfo(Map<String, dynamic> json) {
    if (json['d'] != null) {
      List<DownloadContent> list = DownloadContent.toList(json['d']) ?? [];
      for (DownloadContent v in list) {
        v.url = ".${v.extension}";
      }
      // 写回 Map 而不是 DownloadContent 对象：下面 ensureSectionMediaHash 会 DownloadContent.toList 读回来，对象会强转失败
      json['d'] = list.map((e) => e.toJson()).toList();
    }
    // 外部 doc 只按老规矩排 'd'（第一项当整节媒体），进库前统一补上显式的 'm'，
    // 这样全 App 只认 'm' 一条规则，跟迁移过的老库对齐。
    VerseField.ensureSectionMediaHash(json);
  }

  /// [docRelativePath] 是书本文档（index.json）相对内容根目录的位置。
  /// 书本已经没有自己的目录了，这份文档只是导入期的暂存文件，位置由调用方决定。
  static Future<bool> import(int bookId, String url, String docRelativePath) async {
    Book? book = await Db().db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["book"]));
      return false;
    }
    book.url = url;
    Map<String, dynamic>? jsonData = await DocHelp.toJsonMap(docRelativePath);
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

    Map<String, dynamic> bookContent = {};
    jsonData.forEach((k, v) {
      // 'i' 是课堂文档给每本书带的书本 id，不是书本内容，别写进 content
      if (k != 'c' && k != ClassroomDocField.bookId) {
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
            sort: verseSortOf(book.sort, chapterIndex, verseIndex),
            content: convert.jsonEncode(verseContent),
            contentVersion: 1,
            // 用排计划的"今天"而不是真实日期：凌晨 delayHour 点前还算前一天，写成真实日期的话新句子当天排不进学习计划
            learnDate: ScheduleDao.currentDate(),
            progress: 0,
          ),
        );
      }
    }
    await Db().db.bookDao.import(book, chapters, verses);
    return true;
  }
}
