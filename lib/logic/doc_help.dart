import 'dart:convert';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/base/constant.dart' show DocPath;
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class DocHelp {
  static Future<String?> toJsonString(String path) async {
    var rootPath = await DocPath.getContentPath();
    File file = File(rootPath.joinPath(path));
    bool exist = await file.exists();
    if (!exist) {
      return null;
    }
    return await file.readAsString();
  }

  static Future<Map<String, dynamic>?> toJsonMap(String path) async {
    String? jsonString = await toJsonString(path);
    if (jsonString == null) {
      return null;
    }
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    return jsonData;
  }

  static Future<RepeatDoc?> fromPath(String path) async {
    Map<String, dynamic>? jsonData = await toJsonMap(path);
    if (jsonData != null) {
      return RepeatDoc.fromJson(jsonData);
    }
    return null;
  }

  static List<Download> getDownloads(RepeatDoc kv, {String? rootUrl}) {
    List<Download> ret = [];
    Map<String, Download> hashToDownloads = {};
    void tryAppendDownload(Download d, String? rootUrl) {
      if (hashToDownloads[d.hash] == null) {
        Download? curr;
        if (d.url.startsWith("http")) {
          curr = d;
        } else if (rootUrl != null) {
          curr = Download(url: rootUrl.joinPath(d.url), hash: d.hash);
        }
        if (curr != null) {
          ret.add(curr);
          hashToDownloads[curr.hash] = curr;
        }
      }
    }

    kv.rootUrl ??= rootUrl;
    if (kv.download != null) {
      for (var d in kv.download!) {
        tryAppendDownload(d, kv.rootUrl);
      }
    }
    for (var chapter in kv.chapter) {
      if (chapter.download != null) {
        for (var d in chapter.download!) {
          tryAppendDownload(d, chapter.rootUrl ?? kv.rootUrl);
        }
      }
      for (var verse in chapter.verse) {
        if (verse.download != null) {
          for (var d in verse.download!) {
            tryAppendDownload(d, verse.rootUrl ?? chapter.rootUrl ?? kv.rootUrl);
          }
        }
      }
    }
    return ret;
  }

  static void fixDownloadInfo(Map<String, dynamic> json) {
    json.remove('u');
    if (json['d'] != null) {
      List<Download> list = Download.toList(json['d']) ?? [];
      for (Download v in list) {
        v.url = v.path;
      }
      json['d'] = list;
    }
  }

  static Future<bool> getDocMapFromDb({
    required int contentId,
    required Map<String, dynamic> ret,
    String? rootUrl,
    bool shareNote = false,
  }) async {
    await VerseHelp.tryGen(force: true);
    await ChapterHelp.tryGen(force: true);
    var content = await Db().db.bookDao.getById(contentId);
    var verseCache = VerseHelp.cache;
    var chapterCache = ChapterHelp.cache;

    Map<String, dynamic> contentJson = jsonDecode(content!.content);
    contentJson.forEach((k, v) {
      if (k != 'c') {
        ret[k] = v;
      }
    });

    if (rootUrl != null) {
      fixDownloadInfo(ret);
    }

    Map<int, List<VerseShow>> chapterToVerseShow = {};

    for (var verse in verseCache) {
      if (verse.bookId == contentId) {
        int chapterKey = verse.chapterIndex;

        if (!chapterToVerseShow.containsKey(chapterKey)) {
          chapterToVerseShow[chapterKey] = [];
        }

        chapterToVerseShow[chapterKey]!.add(verse);
      }
    }

    chapterToVerseShow.forEach((chapterIndex, verses) {
      verses.sort((a, b) => a.verseIndex.compareTo(b.verseIndex));
    });

    List<Map<String, dynamic>> chaptersList = [];
    for (int i = 0; i < chapterCache.length; i++) {
      var chapter = chapterCache[i];
      if (chapter.bookId == contentId) {
        Map<String, dynamic> chapterData = {};

        try {
          chapterData = jsonDecode(chapter.chapterContent);
        } catch (e) {
          Snackbar.show('Error parsing chapter content: $e');
          return false;
        }

        List<VerseShow> versesForChapter = chapterToVerseShow[chapter.chapterIndex] ?? [];
        List<Map<String, dynamic>> versesList = [];
        for (var verse in versesForChapter) {
          Map<String, dynamic> verseData = {};

          try {
            verseData = jsonDecode(verse.verseContent);
          } catch (e) {
            Snackbar.show('Error parsing verse content: $e');
            return false;
          }

          if (shareNote && verse.verseNote.isNotEmpty) {
            verseData['n'] = verse.verseNote;
          }
          if (rootUrl != null) {
            fixDownloadInfo(verseData);
          }
          versesList.add(verseData);
        }
        if (rootUrl != null) {
          fixDownloadInfo(chapterData);
        }
        chapterData['v'] = versesList;
        chaptersList.add(chapterData);
      }
    }
    if (rootUrl != null) {
      ret['r'] = rootUrl;
    }
    ret['c'] = chaptersList;

    return true;
  }
}
