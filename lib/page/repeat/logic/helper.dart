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
import 'package:repeat_flutter/logic/widget/media_share/media_share_args.dart';
import 'package:repeat_flutter/logic/widget/media_share/media_share_logic.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'repeat_flow.dart';

class Helper {
  bool initialized = false;
  late RepeatFlow logic;
  MediaShareLogic mediaShareLogic = MediaShareLogic();
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

  RxBool focusMode = true.obs;
  Rx<ShowMode> showMode = ShowMode.closedBook.obs;
  bool enableReloadMedia = true;
  bool resetMediaStart = true;
  bool enablePlayingMedia = false;
  Map<int, Map<String, dynamic>> bookMapCache = {};

  Map<int, Map<String, dynamic>> chapterMapCache = {};

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
      verseMapCache.clear();
    });
    updateBookContentSub.on([EventTopic.updateBookContent], (int? id) {
      bookMapCache.remove(id!);
    });
    updateChapterContentSub.on([EventTopic.updateChapterContent], (ChapterShow? v) {
      if (v == null) return;
      chapterMapCache.remove(v.chapterId);
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

  void stopMedia(bool enableReloadMedia) {
    this.enableReloadMedia = enableReloadMedia;
    enablePlayingMedia = false;
    EventBus().publish<bool>(EventTopic.stopMedia, true);
  }

  void update() {
    logic.update();
  }

  RepeatStep get step {
    return logic.step;
  }

  TipLevel tip = TipLevel.none;

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

  List<String> getRelativePaths() {
    var raw = ListUtil.getValue<List<dynamic>>(
      [
        getCurrVerseMap(),
        getCurrChapterMap(),
        getCurrBookMap(),
      ],
      'd',
    );
    List<String> ret = [];
    var downloads = DownloadContent.toList(raw);
    if (downloads == null) {
      return ret;
    }
    for (var download in downloads) {
      ret.add(download.path);
    }
    return ret;
  }

  List<String> getPaths() {
    List<String> ret = [];
    var paths = getRelativePaths();
    for (var path in paths) {
      ret.add(rootPath.joinPath(DocPath.getRelativePath(logic.currVerse!.bookId)).joinPath(path));
    }
    return ret;
  }

  String? getString(String key) {
    return ListUtil.getValue<String>(
      [
        getCurrVerseMap(),
        getCurrChapterMap(),
        getCurrBookMap(),
      ],
      key,
    );
  }

  String? getCurrViewName() {
    return getString('s');
  }

  Future<bool> tryImportMedia({
    required String localMediaPath,
    required MediaType mediaType,
  }) async {
    var file = File(localMediaPath);
    var exist = await file.exists();
    if (exist) {
      return true;
    } else {
      MsgBox.myDialog(
        title: I18nKey.labelTips.tr,
        content: MsgBox.content(I18nKey.labelFileNotFound.tr),
        action: MsgBox.buttonsWithDivider(
          buttons: [
            MsgBox.button(
              text: I18nKey.btnCancel.tr,
              onPressed: () {
                Get.back();
                Get.back();
              },
            ),
            if (Platform.isIOS)
              MsgBox.button(
                text: I18nKey.openAlbum.tr,
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.video,
                  );
                  await importPickedFile(mediaType, result);
                },
              ),
            if (Platform.isIOS)
              MsgBox.button(
                text: I18nKey.openFile.tr,
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: mediaType.allowedExtensions,
                  );
                  await importPickedFile(mediaType, result);
                },
              ),
            if (!Platform.isIOS)
              MsgBox.button(
                text: I18nKey.btnOk.tr,
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: mediaType.allowedExtensions,
                  );
                  await importPickedFile(mediaType, result);
                },
              ),
          ],
        ),
      );
      return false;
    }
  }

  Future<void> importPickedFile(MediaType mediaType, FilePickerResult? result) async {
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
      if (!mediaType.allowedExtensions.containsIgnoreCase(download.extension)) {
        Snackbar.show(I18nKey.labelFileExtensionNotMatch.trArgs([jsonEncode(mediaType.allowedExtensions)]));
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
  }

  MediaShareCallback? openMediaShare() {
    return () {
      final verse = getCurrVerse();
      if (verse == null) {
        return;
      }
      String path = "";
      List<String> paths = getRelativePaths();
      if (paths.isNotEmpty) {
        path = paths.first;
      } else {
        return;
      }
      mediaShareLogic.open(MediaShareArgs(bookId: verse.bookId, path: path));
    };
  }

  void closeMediaShareWeb() {
    mediaShareLogic.switchWeb(false);
  }
}
