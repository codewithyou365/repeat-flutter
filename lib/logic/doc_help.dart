import 'dart:convert';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart' show DocPath, DownloadConstant;
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
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

  static Future<BookContent?> fromPath(String path) async {
    Map<String, dynamic>? jsonData = await toJsonMap(path);
    if (jsonData != null) {
      return BookContent.fromJson(jsonData);
    }
    return null;
  }

  static List<DownloadContent> getDownloads(BookContent kv, {String? rootUrl}) {
    rootUrl ??= DownloadConstant.defaultUrl;
    List<DownloadContent> ret = [];
    Map<String, DownloadContent> hashToDownloads = {};
    void tryAppendDownload(DownloadContent d, String? rootUrl) {
      if (hashToDownloads[d.hash] == null) {
        DownloadContent? curr;
        if (d.url.startsWith("http")) {
          curr = d;
        } else if (rootUrl != null) {
          curr = DownloadContent(url: rootUrl.joinPath(d.url), hash: d.hash);
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
    if (json['d'] != null) {
      List<DownloadContent> list = DownloadContent.toList(json['d']) ?? [];
      for (DownloadContent v in list) {
        v.url = v.path;
      }
      json['d'] = list;
    }
  }

  static Future<bool> getDocMapFromDb({
    required int bookId,
    required Map<String, dynamic> ret,
    required String? rootUrl,
    required bool note,
    required bool databaseData,
  }) async {
    var content = await Db().db.bookDao.getById(bookId);
    if (content == null) {
      return false;
    }
    var verseCache = await Db().db.scheduleDao.getAllVerse(content.classroomId);
    var chapterCache = await Db().db.chapterDao.getAllChapter(content.classroomId);

    Map<String, dynamic> contentJson = jsonDecode(content.content);
    contentJson.forEach((k, v) {
      if (k != 'c') {
        ret[k] = v;
      }
      if (k == 'g' && v is List) {
        for (var game in v) {
          if (!databaseData && game is Map) {
            game.remove('i');
          }
        }
      }
    });

    if (rootUrl != null) {
      fixDownloadInfo(ret);
    }

    Map<int, List<VerseShow>> chapterToVerseShow = {};

    for (var verse in verseCache) {
      if (verse.bookId == bookId) {
        int chapterIndex = verse.chapterIndex;

        if (!chapterToVerseShow.containsKey(chapterIndex)) {
          chapterToVerseShow[chapterIndex] = [];
        }

        chapterToVerseShow[chapterIndex]!.add(verse);
      }
    }

    chapterToVerseShow.forEach((chapterIndex, verses) {
      verses.sort((a, b) => a.verseIndex.compareTo(b.verseIndex));
    });

    List<Map<String, dynamic>> chaptersList = [];
    for (int i = 0; i < chapterCache.length; i++) {
      var chapter = chapterCache[i];
      if (chapter.bookId == bookId) {
        Map<String, dynamic> chapterData = {};

        try {
          chapterData = jsonDecode(chapter.chapterContent);
        } catch (e) {
          Snackbar.show('Error parsing chapter content: $e');
          return false;
        }
        if (databaseData) {
          chapterData['i'] = chapter.chapterId;
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
          if (databaseData) {
            verseData['i'] = verse.verseId;
            verseData['l'] = verse.learnDate.value;
            verseData['p'] = verse.progress;
          }
          if (!note) {
            verseData.remove('n');
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

  static Future<DownloadContent?> tryCopyToDocDir({
    required int bookId,
    required FilePickerResult? result,
    required List<String> allowedExtensions,
  }) async {
    String pickedPath = "";
    String pickedName = "";
    if (result != null && result.files.single.path != null) {
      pickedPath = result.files.single.path!;
      pickedName = result.files.single.name;
    } else {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return null;
    }

    try {
      final extension = ".${pickedName.split('.').last}";
      if (!allowedExtensions.containsIgnoreCase(extension)) {
        Snackbar.show(I18nKey.labelFileExtensionNotMatch.trArgs([jsonEncode(allowedExtensions)]));
        return null;
      }
      return await moveToDocDir(pickedPath, bookId, true);
    } catch (e) {
      Snackbar.show(e.toString());
      return null;
    }
  }

  static Future<DownloadContent> moveToDocDir(String fromAbsolutePath, int toBookId, [bool copy = false]) async {
    String hash = await Hash.toSha1(fromAbsolutePath);
    String extension = fromAbsolutePath.split('.').last;
    DownloadContent download = DownloadContent(url: ".$extension", hash: hash);

    var rootPath = await DocPath.getContentPath();
    String relativeFolder = DocPath.getRelativePath(toBookId).joinPath(download.folder);
    String localFolder = rootPath.joinPath(relativeFolder);
    String targetPath = localFolder.joinPath(download.name);

    await Folder.ensureExists(localFolder);

    File sourceFile = File(fromAbsolutePath);

    if (copy) {
      await sourceFile.copy(targetPath);
    } else {
      try {
        await sourceFile.rename(targetPath);
      } catch (e) {
        await sourceFile.copy(targetPath);
        await sourceFile.delete();
      }
    }

    return download;
  }
}
