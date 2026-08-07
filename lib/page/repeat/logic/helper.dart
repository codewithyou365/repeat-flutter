import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_brief_help.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/chapter_import_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/model/verse_pos.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/widget/media_share/media_share_args.dart';
import 'package:repeat_flutter/logic/widget/media_share/media_share_logic.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'model_media_range.dart';
import 'repeat_flow.dart';

class Helper {
  bool initialized = false;
  late RepeatFlow logic;
  MediaShareLogic mediaShareLogic = MediaShareLogic();
  TextEditingController practiceController = TextEditingController();
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
  late Widget? Function() practiceArea;
  late Widget? Function() tipArea;

  /// 提示区当前选中的 tab：0..n-1 是第 1..n 条提示，n 是笔记（n = [currTipCount]）。
  /// 朗读、播放区间、扩展助手这些都按它选的那一条走，所以放在 Helper 上而不是只给界面用。
  RxInt currentTipTabIndex = 0.obs;

  /// 提示 tab 栏横着滚的控制器：8 条提示加上名字，一行放不下。
  /// 放在 Helper 上是因为 tipArea 每次重建都会新建 widget，控制器不能跟着重建。
  final ScrollController tipTabScrollController = ScrollController();
  late Widget? Function(QaType type) text;
  late Widget Function() fullScreenPanel;

  RxBool focusMode = true.obs;
  Rx<ShowMode> showMode = ShowMode.closedBook.obs;
  bool enableReloadMedia = true;
  bool doNotPlayMedia = true;
  bool tryToPlayMedia = false;

  /// 当前这一节的三层内容，由 [prefetch] 在切句子时一次性取好。
  ///
  /// 以前这三个是去全局缓存（整个课堂的书/章/句常驻内存）里现查的，现在改成
  /// 只留当前一节 —— 播放页任何时候只需要这一节，多留一条都是白占内存。
  VerseShow? currVerseShow;
  ChapterShow? currChapterShow;
  BookShow? currBookShow;

  /// 标题栏和"下一条"按钮上的位置串，同样在 [prefetch] 里备好 ——
  /// 这两个 label 是 build 里同步读的，不能临时去查库。
  String currPos = '';
  String nextPos = '';
  int? _nextPosVerseId;

  /// bookId -> 书名，只给位置串用。一个课堂几本书，几 KB。
  Map<int, String> bookNames = {};

  /// 解析后的 JSON，跟着 [currVerseShow] 那三个走，只保当前一份。
  Map<String, dynamic>? bookMap;
  Map<String, dynamic>? chapterMap;
  Map<String, dynamic>? verseMap;

  /// 当前课堂的内容，提示的名字/字体/服务配置都在里面（见 ClassroomDocField.tips）。
  /// 跟书/章/句一样是同步读的，所以在 [init] 里取好、内容变了再重取。
  Map<String, dynamic>? classroomMap;

  final SubList<int> reimportBookSub = [];
  final SubList<int> updateBookContentSub = [];
  final SubList<int> updateClassroomContentSub = [];
  final SubList<ChapterShow> updateChapterContentSub = [];
  final SubList<VerseShow> updateVerseContentSub = [];

  Future<void> init(RepeatFlow logic) async {
    this.logic = logic;
    rootPath = await DocPath.getContentPath();
    bookNames = await BookBriefHelp.loadNameMap(Classroom.curr);
    await loadClassroomMap();
    initialized = true;
    // 内容被改过就把当前这一节重新取一遍 —— 这三份数据是我们自己持有的副本，
    // 不像以前那样由 DAO 顺手 patch 全局缓存。
    reimportBookSub.on([EventTopic.reimportBook], (int? id) {
      bookNames.remove(id);
      refetch();
    });
    updateBookContentSub.on([EventTopic.updateBookContent], (int? id) {
      refetch();
    });
    updateClassroomContentSub.on([EventTopic.updateClassroomContent], (int? id) async {
      if (id != null && id != Classroom.curr) return;
      await loadClassroomMap();
      update();
    });
    updateChapterContentSub.on([EventTopic.updateChapterContent], (ChapterShow? v) {
      if (v == null) return;
      if (v.chapterId == currChapterShow?.chapterId) {
        refetch();
      }
    });
    updateVerseContentSub.on([EventTopic.updateVerseContent], (VerseShow? v) {
      if (v == null) return;
      if (v.verseId == currVerseShow?.verseId) {
        refetch();
      }
    });
  }

  /// 切句子时把这一节要用的东西一次性取好。
  ///
  /// 播放页大量取值口子（[getCurrVerseContent]、[getCurrBookMap]、位置串…）都是
  /// build 里同步调的，改不成 async，所以在这里预取，同步 getter 只读字段。
  Future<void> prefetch(VerseTodayPrg? curr, VerseTodayPrg? next) async {
    if (curr == null) {
      currVerseShow = null;
      currChapterShow = null;
      currBookShow = null;
      bookMap = null;
      chapterMap = null;
      verseMap = null;
      currPos = '';
      nextPos = '';
      _nextPosVerseId = null;
      return;
    }
    if (currVerseShow?.verseId != curr.verseId) {
      currVerseShow = await Db().db.scheduleDao.getVerseShowById(curr.verseId);
      verseMap = null;
    }
    if (currChapterShow?.chapterId != curr.chapterId) {
      currChapterShow = await Db().db.chapterDao.getChapterShowById(curr.chapterId);
      chapterMap = null;
    }
    if (currBookShow?.bookId != curr.bookId) {
      currBookShow = await Db().db.bookDao.getBookShowById(curr.bookId);
      bookMap = null;
    }
    var v = currVerseShow;
    currPos = v == null ? '' : versePos(bookNames[v.bookId] ?? '', v.chapterIndex, v.verseIndex);

    if (next == null) {
      nextPos = '';
      _nextPosVerseId = null;
    } else if (_nextPosVerseId != next.verseId) {
      // 只要位置串，取到手就把 VerseShow 丢掉，不留正文
      var n = await Db().db.scheduleDao.getVerseShowById(next.verseId);
      nextPos = n == null ? '' : versePos(bookNames[n.bookId] ?? '', n.chapterIndex, n.verseIndex);
      _nextPosVerseId = next.verseId;
    }
  }

  /// 内容被改过，当前这一节重取一遍。
  Future<void> refetch() async {
    currVerseShow = null;
    currChapterShow = null;
    currBookShow = null;
    bookMap = null;
    chapterMap = null;
    verseMap = null;
    _nextPosVerseId = null;
    await prefetch(logic.currVerse, logic.nextVerse);
    update();
  }

  void onClose() {
    reimportBookSub.off();
    updateBookContentSub.off();
    updateClassroomContentSub.off();
    updateChapterContentSub.off();
    updateVerseContentSub.off();
  }

  void stopMedia(bool enableReloadMedia) {
    tryToPlayMedia = false;
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
    return currVerseShow?.verseContent;
  }

  String? getCurrChapterContent() {
    return currChapterShow?.chapterContent;
  }

  String? getCurrBookContent() {
    return currBookShow?.bookContent;
  }

  Map<String, dynamic>? getCurrBookMap() {
    if (bookMap != null) {
      return bookMap;
    }
    String? rootContent = getCurrBookContent();
    if (rootContent == null) {
      return null;
    }
    var ret = jsonDecode(rootContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    bookMap = ret;
    return ret;
  }

  /// 课堂内容重取一遍。写课堂内容的地方（改提示名字/字体…）会发
  /// [EventTopic.updateClassroomContent]，走到这里。
  Future<void> loadClassroomMap() async {
    classroomMap = null;
    final classroom = await Db().db.classroomDao.getById(Classroom.curr);
    final content = classroom?.content;
    if (content == null || content.isEmpty) {
      return;
    }
    try {
      final ret = jsonDecode(content);
      classroomMap = ret is Map<String, dynamic> ? ret : null;
    } catch (_) {
      classroomMap = null;
    }
  }

  /// 提示的名字/字体/服务配置都从这里读，见 ClassroomDocField.tips。
  Map<String, dynamic>? getClassroomMap() {
    return classroomMap;
  }

  Map<String, dynamic>? getCurrChapterMap() {
    if (chapterMap != null) {
      return chapterMap;
    }
    String? chapterContent = getCurrChapterContent();
    if (chapterContent == null) {
      return null;
    }
    var ret = jsonDecode(chapterContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    chapterMap = ret;
    return ret;
  }

  VerseTodayPrg? getCurrVerse() {
    return logic.currVerse;
  }

  Map<String, dynamic>? getCurrVerseMap() {
    if (verseMap != null) {
      return verseMap;
    }
    String? verseContent = getCurrVerseContent();
    if (verseContent == null) {
      return null;
    }
    var ret = jsonDecode(verseContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    verseMap = ret;
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

  /// 整节媒体：q/a/t 都没配字段专属媒体时播的那一份。
  DownloadContent? getSectionDownload() {
    return VerseField.findSectionDownload(fieldLevels);
  }

  String? getSectionRelativePath() => getSectionDownload()?.path;

  String? getSectionPath() {
    final d = getSectionDownload();
    return d == null ? null : getPath(d.path);
  }

  String getPath(String downloadPath) {
    return rootPath.joinPath(DocPath.getRelativePath(logic.currVerse!.bookId)).joinPath(downloadPath);
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

  /// verse -> chapter -> book，字段块按这个顺序继承（整章共用一个媒体时只在 chapter 上写一次）。
  List<Map<String, dynamic>?> get fieldLevels => [getCurrVerseMap(), getCurrChapterMap(), getCurrBookMap()];

  /// 这一节该显示几个提示 tab。
  int currTipCount() => VerseField.tipCount(getCurrVerseMap(), getClassroomMap());

  /// 当前选中的那一条提示的字段引用串（'t'/'t1'/'t2'…）。
  /// 选中的是笔记 tab（或者下标越界了）时退回第 1 条，这样朗读、播放这些永远有个确定的目标。
  String currTipRef() {
    final index = clampedTipTabIndex();
    if (index >= currTipCount()) {
      return QaType.tip.acronym;
    }
    return VerseField.ref(QaType.tip.acronym, index);
  }

  /// 换书后提示条数会变，存着的下标可能落在不存在的提示上，读的时候收回到最后一个合法位置
  /// （最后一个是笔记 tab）。
  int clampedTipTabIndex() {
    final max = currTipCount();
    final index = currentTipTabIndex.value;
    return index < 0 ? 0 : (index > max ? max : index);
  }

  /// 某个字段（'q'/'a'/'t'）专属的媒体文件：字段块里只有 mediaHash，文件对象在某一层的 'd' 里。
  /// 没有配就返回 null，走整节的 'd'。
  DownloadContent? getFieldDownload(String acronym) {
    final levels = fieldLevels;
    final hash = VerseField.lookup(levels, acronym, VerseField.mediaHash);
    if (hash == null) {
      return null;
    }
    return VerseField.findDownloadByHash(levels, hash);
  }

  String? getFieldPath(String acronym) {
    final d = getFieldDownload(acronym);
    if (d == null) {
      return null;
    }
    return getPath(d.path);
  }

  /// 悬浮球 Play-* 临时指定的字段：比如 evaluate 阶段点 Play-Q，界面要切到 q 的媒体和区间
  /// （视图类型、播放的文件、MediaBar 的起止点都跟着走），下一次翻页/切步骤时由 preClick 清掉。
  String? playFieldOverride;

  /// 当前这一步对应的字段：闭卷回忆阶段放问题，其余阶段放答案；主字段没有配时间区间就退到另一个。
  /// 这个优先级必须跟 MediaRangeHelper.getCurrRange() 一致，否则会出现"区间取的是 q、视图却按 a 选"。
  String currFieldAcronym() {
    final override = playFieldOverride;
    if (override != null) {
      return override;
    }
    final primary = step == RepeatStep.recall ? QaType.question.acronym : QaType.answer.acronym;
    final secondary = step == RepeatStep.recall ? QaType.answer.acronym : QaType.question.acronym;
    if (_hasRange(primary)) {
      return primary;
    }
    if (_hasRange(secondary)) {
      return secondary;
    }
    return primary;
  }

  bool _hasRange(String acronym) {
    final map = getCurrVerseMap();
    if (map == null) {
      return false;
    }
    final start = VerseField.getStr(map, acronym, VerseField.start);
    final end = VerseField.getStr(map, acronym, VerseField.end);
    return start != null && end != null;
  }

  /// 某个字段自己的视图类型：优先取显式写下的 'a'.'showType'（整节的 's' 是 q/a 共用的，
  /// 一节里 q 是视频、a 是音频时只能各记各的），没有就按该字段媒体的扩展名推。都没有返回 null。
  String? getFieldViewName(String acronym) {
    final map = getCurrVerseMap();
    if (map == null) {
      return null;
    }
    final showType = VerseField.lookup(fieldLevels, acronym, VerseField.showType);
    if (showType != null) {
      return showType;
    }
    final d = getFieldDownload(acronym);
    if (d != null) {
      return ChapterImportHelp.showTypeForExtension(d.extension);
    }
    return null;
  }

  /// 整节（verse/chapter/book 的 's'）的视图类型，也就是整节那份媒体 'd' 对应的类型。
  String? getSectionViewName() {
    return getString('s');
  }

  /// 视图类型：先看当前这一步的字段有没有自己的视图类型，没有才回落到整节的 's'。
  String? getCurrViewName() {
    return getFieldViewName(currFieldAcronym()) ?? getSectionViewName();
  }

  Future<bool> tryImportMedia({
    required String localMediaPath,
    required MediaType mediaType,
    required DownloadContent out,
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
            MsgBox.button(
              text: I18nKey.openAlbum.tr,
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.video,
                );
                var download = await importPickedFile(mediaType, result);
                out.url = download?.url ?? '';
                out.hash = download?.hash ?? '';
              },
            ),
            MsgBox.button(
              text: I18nKey.openFile.tr,
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: mediaType.allowedExtensions,
                );
                var download = await importPickedFile(mediaType, result);
                out.url = download?.url ?? '';
                out.hash = download?.hash ?? '';
              },
            ),
          ],
        ),
      );
      return false;
    }
  }

  Future<DownloadContent?> importPickedFile(MediaType mediaType, FilePickerResult? result) async {
    try {
      var s = getCurrVerse()!;
      var download = await DocHelp.tryCopyToDocDir(
        bookId: s.bookId,
        result: result,
        allowedExtensions: mediaType.allowedExtensions,
      );
      if (download == null) {
        return null;
      }
      var chapterId = s.chapterId;
      var m = getCurrChapterMap()!;
      VerseField.setSectionMedia(m, download);
      Db().db.chapterDao.updateChapterContent(chapterId, jsonEncode(m));
      Get.back();
      Get.back();
      return download;
    } catch (e) {
      Snackbar.show(e.toString());
      return null;
    }
  }

  MediaShareCallback? openMediaShare() {
    return () {
      final verse = getCurrVerse();
      if (verse == null) {
        return;
      }
      final path = getSectionRelativePath();
      if (path == null) {
        return;
      }
      mediaShareLogic.open(MediaShareArgs(bookId: verse.bookId, path: path));
    };
  }

  MediaCropAndSaveCallback? cropAndSaveMedia({
    required RxString path,
    required MediaRange range,
  }) {
    if (showMode.value != ShowMode.edit) {
      return null;
    }
    var verse = getCurrVerse();
    if (verse == null) {
      return null;
    }
    return () async {
      await innerTrimMedia(verse, path, range);
    };
  }

  Future<void> innerTrimMedia(VerseTodayPrg verse, RxString path, MediaRange range) async {
    try {
      double startSeconds = range.start / 1000.0;
      int durationMs = range.end - range.start;
      double durationSeconds = durationMs / 1000.0;

      var rootPath = await DocPath.getContentPath();
      String directory = rootPath.joinPath('media');
      final String extension = p.extension(path.value);
      final String fileName = p.basenameWithoutExtension(path.value);
      await Folder.ensureExists(directory);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath = p.join(directory, "${fileName}_trimmed_$timestamp$extension");

      showOverlay(() async {
        final session = await FFmpegKit.execute("-ss $startSeconds -t $durationSeconds -i '$path' -acodec copy '$outputPath'");

        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          final dc = await DocHelp.moveToDocDir(outputPath, verse.bookId);
          var verseMap = getCurrVerseMap();
          if (verseMap == null) {
            return null;
          }
          // 裁的是字段专属媒体时，裁完的文件仍然只属于这个字段，不能写成整节媒体，
          // 否则字段还指着老文件、时间区间却按新文件算，两边对不上。
          if (getFieldDownload(range.fieldAcronym) != null) {
            VerseField.setMedia(verse: verseMap, acronym: range.fieldAcronym, d: dc);
          } else {
            // 裁的是整节媒体：只把这一节的整节媒体换成裁出来的文件，chapter/book 不动。
            VerseField.setSectionMedia(verseMap, dc);
          }
          VerseField.setStr(verseMap, range.fieldAcronym, VerseField.start, "00:00:00,000");
          VerseField.setStr(verseMap, range.fieldAcronym, VerseField.end, Time.convertMsToString(durationMs + 100));
          String jsonStr = jsonEncode(verseMap);
          await Db().db.verseDao.updateVerseContent(verse.verseId, jsonStr);
          logic.update();
          Snackbar.show(I18nKey.labelSaved.tr);
        } else {
          final failStackTrace = await session.getFailStackTrace();
          Get.back();
          Snackbar.show("Trim failed: $failStackTrace");
        }
      }, I18nKey.cutting.tr);
    } catch (e) {
      Snackbar.show("Error during trimming: $e");
    }
  }
}
