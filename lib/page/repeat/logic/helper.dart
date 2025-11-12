import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'repeat_flow.dart';

class Helper {
  bool initialized = false;
  late RepeatFlow logic;
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
  late Widget Function() closeEyesPanel;

  bool concentrationMode = true;
  bool edit = false;
  bool enableReloadMedia = true;
  bool resetMediaStart = true;
  bool enablePlayingPlayMedia = false;
  Map<int, Map<String, dynamic>> bookMapCache = {};

  Map<int, Map<String, dynamic>> chapterMapCache = {};
  Map<int, List<String>> chapterPathCache = {};

  Map<int, Map<String, dynamic>> verseMapCache = {};

  final SubList<int> reimportBookSub = [];
  final SubList<int> updateBookContentSub = [];
  final SubList<ChapterShow> updateChapterContentSub = [];
  final SubList<VerseShow> updateVerseContentSub = [];

  Future<void> init(RepeatFlow logic) async {
    this.logic = logic;
    rootPath = await DocPath.getContentPath();
    initialized = true;
    reimportBookSub.on([EventTopic.reimportBook], (int? id) {
      bookMapCache.remove(id!);
      chapterMapCache.clear();
      chapterPathCache.clear();
      verseMapCache.clear();
    });
    updateBookContentSub.on([EventTopic.updateBookContent], (int? id) {
      bookMapCache.remove(id!);
    });
    updateChapterContentSub.on([EventTopic.updateChapterContent], (ChapterShow? v) {
      if (v == null) return;
      chapterMapCache.remove(v.chapterId);
      chapterPathCache.remove(v.chapterId);
    });
    updateVerseContentSub.on([EventTopic.updateVerseContent], (VerseShow? v) {
      if (v == null) return;
      verseMapCache.remove(v.verseId);
    });
  }

  void onClose() {
    reimportBookSub.off();
    updateBookContentSub.off();
    updateChapterContentSub.off();
    updateVerseContentSub.off();
  }

  void setInRepeatView(bool inRepeatView) {
    enableReloadMedia = inRepeatView;
    enablePlayingPlayMedia = false;
    EventBus().publish<bool>(EventTopic.setInRepeatView, inRepeatView);
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
    var verse = VerseHelp.getCache(logic.currVerse!.verseId);
    if (verse == null) {
      return null;
    }
    return verse.verseContent;
  }

  String? getCurrChapterContent() {
    if (logic.currVerse == null) {
      return null;
    }
    var chapter = ChapterHelp.getCache(logic.currVerse!.chapterId);
    if (chapter == null) {
      return null;
    }
    return chapter.chapterContent;
  }

  String? getCurrBookContent() {
    if (logic.currVerse == null) {
      return null;
    }
    BookShow? ret = BookHelp.getCache(logic.currVerse!.bookId);
    if (ret == null) {
      return null;
    }
    return ret.bookContent;
  }

  Map<String, dynamic>? getCurrBookMap() {
    if (logic.currVerse == null) {
      return null;
    }
    Map<String, dynamic>? ret = bookMapCache[logic.currVerse!.bookId];
    if (ret != null) {
      return ret;
    }
    String? rootContent = getCurrBookContent();
    if (rootContent == null) {
      return null;
    }
    ret = jsonDecode(rootContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    bookMapCache[logic.currVerse!.bookId] = ret;
    return ret;
  }

  Map<String, dynamic>? getCurrChapterMap() {
    if (logic.currVerse == null) {
      return null;
    }
    Map<String, dynamic>? ret = chapterMapCache[logic.currVerse!.chapterId];
    if (ret != null) {
      return ret;
    }
    String? chapterContent = getCurrChapterContent();
    if (chapterContent == null) {
      return null;
    }
    ret = jsonDecode(chapterContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    chapterMapCache[logic.currVerse!.chapterId] = ret;
    return ret;
  }

  VerseTodayPrg? getCurrVerse() {
    return logic.currVerse;
  }

  Map<String, dynamic>? getCurrVerseMap() {
    if (logic.currVerse == null) {
      return null;
    }
    Map<String, dynamic>? ret = verseMapCache[logic.currVerse!.verseId];
    if (ret != null) {
      return ret;
    }
    String? verseContent = getCurrVerseContent();
    if (verseContent == null) {
      return null;
    }
    ret = jsonDecode(verseContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    verseMapCache[logic.currVerse!.verseId] = ret;
    return ret;
  }

  Map<String, dynamic>? getCurrRepeatDocMap() {
    if (logic.currVerse == null) {
      return null;
    }
    String? rootContent = getCurrBookContent();
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

  BookContent? getCurrRepeatDoc() {
    if (logic.currVerse == null) {
      return null;
    }
    final map = getCurrRepeatDocMap();
    if (map == null) {
      return null;
    }
    return BookContent.fromJson(map);
  }

  List<String>? getChapterPaths() {
    if (logic.currVerse == null) {
      return null;
    }
    List<String>? ret = chapterPathCache[logic.currVerse!.chapterId];
    if (ret != null) {
      return ret;
    }
    var doc = getCurrChapterMap();
    if (doc == null) {
      return null;
    }
    ChapterContent chapter = ChapterContent.fromJson(doc);
    var downloads = chapter.download ?? [];
    ret = [];
    for (var download in downloads) {
      ret.add(rootPath.joinPath(DocPath.getRelativePath(logic.currVerse!.bookId)).joinPath(download.path));
    }
    chapterPathCache[logic.currVerse!.chapterId] = ret;
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
      m = getCurrBookMap();
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
            DownloadContent download = DownloadContent(url: ".${pickedName.split('.').last}", hash: hash);
            var rootPath = await DocPath.getContentPath();
            String localFolder = rootPath.joinPath(DocPath.getRelativePath(s.bookId).joinPath(download.folder));
            if (!allowedExtensions.containsIgnoreCase(download.extension)) {
              Snackbar.show(I18nKey.labelFileExtensionNotMatch.trArgs([jsonEncode(allowedExtensions)]));
              return;
            }

            await Folder.ensureExists(localFolder);
            await File(pickedPath).copy(localFolder.joinPath(download.name));
            var chapterId = s.chapterId;
            var m = getCurrChapterMap()!;
            m['d'] = [download];
            Db().db.chapterDao.updateChapterContent(chapterId, jsonEncode(m));
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
