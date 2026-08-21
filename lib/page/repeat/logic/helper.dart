import 'dart:async';
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
import 'package:repeat_flutter/db/entity/cr_kv.dart';
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

  /// 练习输入框的草稿写库防抖。强杀进程时 onClose 不会执行，所以不能只在退出时写，
  /// 打字停下来就落库（见 [loadPracticeDraft]）。
  Timer? _practiceSaveTimer;
  bool _practiceDraftLoaded = false;
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

  /// 配图区。跟 [practiceArea]/[tipArea] 一样是页面侧注入、各视图消费：
  /// 图片跟视图类型是正交的（文本/音频/视频三种视图都可能配图），
  /// 所以它不是第四种视图，而是三种视图共用的一块内容。
  late Widget? Function() imageArea;

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

  /// 重建后这一次自动播放要从哪个位置开始（整个媒体文件的毫秒数）。为 null 就跟以前一样
  /// 从区间起点放。辅助触控里"指定目标"的播放/暂停、后退用它接上该字段上次的点位。
  /// 用完即清（见 RepeatViewForAudio/Video 的 body）。
  int? playAtMs;

  /// 各字段（'q'/'a'/'t1'…）上次离开时进度条停在哪（毫秒）。
  /// 只对当前这一节有效，翻到别的小节就作废（见 [prefetch]）。
  final Map<String, int> lastPlayPosMs = {};
  int? _lastPlayPosVerseId;

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
    // 点位是按小节记的：换了小节，上一节各字段的点位全部作废。
    // 用单独的 _lastPlayPosVerseId 判断，不跟着 currVerseShow 走——内容被改过时
    // refetch() 会把 currVerseShow 清成 null，那种"原地重取"不该丢掉点位。
    if (_lastPlayPosVerseId != curr.verseId) {
      _lastPlayPosVerseId = curr.verseId;
      lastPlayPosMs.clear();
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

  /// 取回上次的练习草稿并挂上自动保存。先赋值再挂监听，免得恢复动作自己触发一次写库。
  Future<void> loadPracticeDraft() async {
    practiceController.text = await Db().db.crKvDao.getStr(Classroom.curr, CrK.practiceDraft) ?? '';
    practiceController.addListener(_onPracticeChanged);
    _practiceDraftLoaded = true;
  }

  void _onPracticeChanged() {
    _practiceSaveTimer?.cancel();
    _practiceSaveTimer = Timer(const Duration(milliseconds: 500), _savePracticeDraft);
  }

  Future<void> _savePracticeDraft() async {
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.practiceDraft, practiceController.text));
  }

  /// 退出播放页时把还没到防抖时间的最后一次输入写掉，并在 controller 被 dispose 前摘掉监听。
  Future<void> flushPracticeDraft() async {
    // 没加载过就别写：init 失败直接退页时，输入框还是空的，写下去会把上次的草稿冲掉。
    if (!_practiceDraftLoaded) {
      return;
    }
    _practiceDraftLoaded = false;
    _practiceSaveTimer?.cancel();
    _practiceSaveTimer = null;
    practiceController.removeListener(_onPracticeChanged);
    await _savePracticeDraft();
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
    return rootPath.joinPath(DocPath.getFilesRelativePath()).joinPath(downloadPath);
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

  /// 这个字段此刻在界面上露不露脸。
  ///
  /// 正文（repeat_page.text）和配图（[getCurrImages]）必须共用同一份判断：闭卷回忆阶段
  /// 答案正文是藏着的，答案的配图要是照显，等于把答案直接给出去了。
  bool fieldVisible(String acronym) {
    if (showMode.value == ShowMode.edit) {
      return true;
    }
    final base = VerseField.baseOf(acronym);
    if (base == QaType.answer.acronym) {
      return step != RepeatStep.recall;
    }
    if (base == QaType.tip.acronym) {
      return tip == TipLevel.tip;
    }
    return true;
  }

  /// 配图跟着"这一步在讲哪个字段"走，而不是复用 [currFieldAcronym]：
  /// 后者会因为某个字段没配时间区间就退到另一个字段——那是播放器要解决的事，
  /// 配图不涉及区间，不该被区间牵着走。悬浮球的 Play-* 临时指定了字段时跟着它。
  String currImageFieldAcronym() {
    return playFieldOverride ?? (step == RepeatStep.recall ? QaType.question.acronym : QaType.answer.acronym);
  }

  /// 当前该显示哪几张图，以及这一组是从哪儿来的。
  ///
  /// 当前这一步的字段自己配了图、而且这个字段此刻可见，就显示它那一组（fromField = true）；
  /// 否则退回整节配图 'g'——整节图是 q/a 共用的场景图，不是任何一方的答案，哪个阶段都能显示。
  ///
  /// 字段图**覆盖**整节图而不是叠加，跟字段媒体盖掉整节媒体是同一套就近覆盖语义。
  ///
  /// fromField 是给编辑态用的：加图/删图要落到当前这一组所在的那个位置，
  /// 不然点"再加一张"会凭空冒出一组字段图把整节图挡掉。
  ({List<DownloadContent> images, bool fromField}) getCurrImageGroup() {
    final levels = fieldLevels;
    if (levels.first == null) {
      return (images: const <DownloadContent>[], fromField: false);
    }
    final acronym = currImageFieldAcronym();
    if (fieldVisible(acronym)) {
      final ret = VerseField.resolveImages(levels, VerseField.fieldImageHashes(levels, acronym));
      if (ret.isNotEmpty) {
        return (images: ret, fromField: true);
      }
    }
    final section = VerseField.resolveImages(levels, VerseField.sectionImageHashes(levels));
    return (images: section, fromField: false);
  }

  /// 配图的绝对路径，按 [getCurrImageGroup] 的顺序。
  List<String> getCurrImagePaths() {
    return getCurrImageGroup().images.map((e) => getPath(e.path)).toList();
  }

  /// 改这一节的配图并存库。[toField] 决定改的是字段图还是整节图，
  /// [edit] 就地增删 hash 列表，[register] 是这次新加的图（要登记进 'd'）。
  ///
  /// 配图是就近覆盖的：当前生效的那一组可能写在 chapter/book 上。直接往 verse 上删一个 hash
  /// 等于删了个不存在的键，界面上图纹丝不动。所以改之前先把整组读出来，改完整份写回 verse——
  /// verse 写了就盖掉上层，这是覆盖语义本来就成立的事。
  ///
  /// 改完一张不剩时：上层还写着这个键的话必须留一个空数组（"这一节明确不要图"，
  /// [VerseField.fieldImageHashes] 认的是键在不在，不是列表空不空），上层没写就把键整个删掉，
  /// 免得到处留下 'imageHash': []。
  Future<bool> editCurrImages({
    required bool toField,
    DownloadContent? register,
    required void Function(List<String> hashes) edit,
  }) async {
    final verse = getCurrVerse();
    final verseMap = getCurrVerseMap();
    if (verse == null || verseMap == null) {
      return false;
    }
    final levels = fieldLevels;
    final upper = levels.skip(1).toList();
    final acronym = currImageFieldAcronym();

    final hashes = toField ? VerseField.fieldImageHashes(levels, acronym) : VerseField.sectionImageHashes(levels);
    edit(hashes);
    if (register != null) {
      VerseField.addDownload(verseMap, register);
    }
    if (hashes.isNotEmpty) {
      if (toField) {
        VerseField.setFieldImages(verseMap, acronym, hashes);
      } else {
        VerseField.setSectionImages(verseMap, hashes);
      }
    } else if (toField) {
      if (VerseField.fieldImageDeclared(upper, acronym)) {
        VerseField.setFieldImages(verseMap, acronym, hashes);
      } else {
        VerseField.remove(verseMap, acronym, [VerseField.imageHash]);
      }
    } else {
      if (VerseField.sectionImageDeclared(upper)) {
        VerseField.setSectionImages(verseMap, hashes);
      } else {
        verseMap.remove(VerseField.sectionImageHash);
      }
    }
    await Db().db.verseDao.updateVerseContent(verse.verseId, jsonEncode(verseMap));
    return true;
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
          final dc = await DocHelp.moveToDocDir(outputPath);
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
