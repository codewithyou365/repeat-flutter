import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/dao/chapter_key_dao.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'repeat_logic.dart';

class Helper {
  bool initialized = false;
  late RepeatLogic logic;
  late List<Book> contents;
  late String rootPath;

  late double screenWidth;
  late double screenHeight;
  bool landscape = false;
  late double leftPadding;
  late double topPadding;
  double topBarHeight = 50;
  late Widget Function() topBar;
  double bottomBarHeight = 50;
  late Widget Function({required double width}) bottomBar;
  late Widget? Function(QaType type) text;

  bool edit = false;
  Map<int, Map<String, dynamic>> rootMapCache = {};

  Map<int, Map<String, dynamic>> chapterMapCache = {};
  Map<int, List<String>> chapterPathCache = {};

  Map<int, Map<String, dynamic>> verseMapCache = {};

  Helper() {
    ChapterKeyDao.setChapterShowContent = [];
    ChapterKeyDao.setChapterShowContent.add((int id) {
      chapterMapCache.remove(id);
      chapterPathCache.remove(id);
    });

    ScheduleDao.setVerseShowContent = [];
    ScheduleDao.setVerseShowContent.add((int id) {
      verseMapCache.remove(id);
    });
  }

  Future<void> init(RepeatLogic logic) async {
    initialized = true;
    this.logic = logic;
    contents = await Db().db.bookDao.getAll(Classroom.curr);
    rootPath = await DocPath.getContentPath();
  }

  void update() {
    logic.update();
  }

  RepeatStep get step {
    return logic.step;
  }

  TipLevel get tip {
    return logic.tip;
  }

  String? getCurrVerseContent() {
    if (logic.currVerse == null) {
      return null;
    }
    var verse = VerseHelp.getCache(logic.currVerse!.verseKeyId);
    if (verse == null) {
      return null;
    }
    return verse.verseContent;
  }

  String? getCurrChapterContent() {
    if (logic.currVerse == null) {
      return null;
    }
    var chapter = ChapterHelp.getCache(logic.currVerse!.chapterKeyId);
    if (chapter == null) {
      return null;
    }
    return chapter.chapterContent;
  }

  String? getCurrRootContent() {
    if (logic.currVerse == null) {
      return null;
    }
    Book ret = contents.firstWhere((c) => c.serial == logic.currVerse!.bookSerial, orElse: () => Book.empty());
    if (ret.id == null) {
      return null;
    }
    return ret.content;
  }

  Map<String, dynamic>? getCurrRootMap() {
    if (logic.currVerse == null) {
      return null;
    }
    Map<String, dynamic>? ret = rootMapCache[logic.currVerse!.bookSerial];
    String? rootContent = getCurrRootContent();
    if (rootContent == null) {
      return null;
    }
    ret = jsonDecode(rootContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    rootMapCache[logic.currVerse!.bookSerial] = ret;
    return ret;
  }

  Map<String, dynamic>? getCurrChapterMap() {
    if (logic.currVerse == null) {
      return null;
    }
    Map<String, dynamic>? ret = chapterMapCache[logic.currVerse!.chapterKeyId];
    String? chapterContent = getCurrChapterContent();
    if (chapterContent == null) {
      return null;
    }
    ret = jsonDecode(chapterContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    chapterMapCache[logic.currVerse!.chapterKeyId] = ret;
    return ret;
  }

  VerseTodayPrg? getCurrVerse() {
    return logic.currVerse;
  }

  Map<String, dynamic>? getCurrVerseMap() {
    if (logic.currVerse == null) {
      return null;
    }
    Map<String, dynamic>? ret = verseMapCache[logic.currVerse!.verseKeyId];
    String? verseContent = getCurrVerseContent();
    if (verseContent == null) {
      return null;
    }
    ret = jsonDecode(verseContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    verseMapCache[logic.currVerse!.verseKeyId] = ret;
    return ret;
  }

  Map<String, dynamic>? getCurrRepeatDocMap() {
    if (logic.currVerse == null) {
      return null;
    }
    String? rootContent = getCurrRootContent();
    if (rootContent == null) {
      return null;
    }
    String? chapterContent = getCurrChapterContent();
    if (chapterContent == null) {
      return null;
    }

    var verseJsonMap = getCurrVerseMap();
    var rootJsonMap = jsonDecode(rootContent);
    var chapterJsonMap = jsonDecode(chapterContent);
    chapterJsonMap['v'] = [verseJsonMap];
    rootJsonMap['c'] = [chapterJsonMap];
    return rootJsonMap;
  }

  RepeatDoc? getCurrRepeatDoc() {
    if (logic.currVerse == null) {
      return null;
    }
    final map = getCurrRepeatDocMap();
    if (map == null) {
      return null;
    }
    return RepeatDoc.fromJson(map);
  }

  List<String>? getChapterPaths() {
    if (logic.currVerse == null) {
      return null;
    }
    List<String>? ret = chapterPathCache[logic.currVerse!.chapterKeyId];
    if (ret != null) {
      return ret;
    }
    var doc = getCurrChapterMap();
    if (doc == null) {
      return null;
    }
    Chapter chapter = Chapter.fromJson(doc);
    var downloads = chapter.download ?? [];
    ret = [];
    for (var download in downloads) {
      ret.add(rootPath.joinPath(DocPath.getRelativePath(logic.currVerse!.bookSerial)).joinPath(download.path));
    }
    chapterPathCache[logic.currVerse!.chapterKeyId] = ret;
    return ret;
  }

  String? getCurrViewName() {
    String? ret;
    var m = getCurrVerseMap();
    if (m != null && m['s'] != null) {
      ret = m['s'] as String;
    }
    if (ret == null) {
      m = getCurrChapterMap();
      if (m != null && m['s'] != null) {
        ret = m['s'] as String;
      }
    }
    if (ret == null) {
      m = getCurrRootMap();
      if (m != null && m['s'] != null) {
        ret = m['s'] as String;
      }
    }
    if (ret != null) {
      return ret.toLowerCase();
    }
    return null;
  }

  Future<bool> tryImportMedia({
    required String localMediaPath,
    required List<String> allowedExtensions,
  }) async {
    var file = File(localMediaPath);
    var exist = await file.exists();
    if (exist) {
      return true;
    } else {
      MsgBox.yesOrNo(
        title: I18nKey.labelTips.tr,
        desc: I18nKey.labelFileNotFound.tr,
        no: () async {
          Get.back();
          Get.back();
        },
        yes: () async {
          FilePickerResult? result;
          if (allowedExtensions.length == 1 && allowedExtensions.first == 'mp4') {
            result = await FilePicker.platform.pickFiles(
              type: FileType.video,
            );
          } else {
            result = await FilePicker.platform.pickFiles(
              type: FileType.media,
            );
          }

          String pickedPath = "";
          String pickedName = "";
          if (result != null && result.files.single.path != null) {
            pickedPath = result.files.single.path!;
            pickedName = result.files.single.name;
          } else {
            Snackbar.show(I18nKey.labelLocalImportCancel.tr);
            return;
          }

          try {
            var s = getCurrVerse()!;
            String hash = await Hash.toSha1(pickedPath);
            Download download = Download(url: pickedName, hash: hash);
            var rootPath = await DocPath.getContentPath();
            String localFolder = rootPath.joinPath(DocPath.getRelativePath(s.bookSerial).joinPath(download.folder));
            if (!allowedExtensions.containsIgnoreCase(download.extension)) {
              Snackbar.show(I18nKey.labelFileExtensionNotMatch.trArgs([jsonEncode(allowedExtensions)]));
              return;
            }

            await Folder.ensureExists(localFolder);
            await File(pickedPath).copy(localFolder.joinPath(download.name));
            var chapterKeyId = s.chapterKeyId;
            var m = getCurrChapterMap()!;
            m['d'] = [download];
            Db().db.chapterKeyDao.updateChapterContent(chapterKeyId, jsonEncode(m));
            Get.back();
            Get.back();
          } catch (e) {
            Snackbar.show(e.toString());
            return;
          }
        },
      );
      return false;
    }
  }
}
