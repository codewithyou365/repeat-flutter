import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse_content_version.dart';
import 'package:repeat_flutter/db/query/chapter_query.dart';
import 'package:repeat_flutter/db/query/show_window.dart';
import 'package:repeat_flutter/db/query/verse_query.dart';
import 'package:repeat_flutter/logic/book_brief_help.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_brief.dart';
import 'package:repeat_flutter/logic/model/verse_pos.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/search/verse_search_index.dart';
import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/logic/view_logic.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/page/repeat/logic/model_media_range.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ViewLogicVerseList<T extends GetxController> extends ViewLogic {
  static const String bodyId = "VerseList.bodyId";
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  /// 点某一行进播放页：传的是**当前过滤+排序下的全部 verseId**和起始下标，
  /// 不是一整份带正文的列表 —— 正文由播放页按当前这一节现取。
  final void Function(List<int> verseIds, int index) onNext;
  List<I18nKey> sortOptionKeys = [
    I18nKey.labelSortPositionAsc,
    I18nKey.labelSortPositionDesc,
    I18nKey.labelSortProgressAsc,
    I18nKey.labelSortProgressDesc,
    I18nKey.labelSortNextLearnDateAsc,
    I18nKey.labelSortNextLearnDateDesc,
  ];
  RxString search = RxString("");
  int selectedSortIndex = 0;

  List<OptionBody> options = [];

  /// bookId -> 书名。**只给界面显示用**，过滤/分组一律拿 bookId 比。
  Map<int, String> bookNames = {};

  RxInt chapterSelect = 0.obs;
  int progressSelect = 0;
  int nextMonthSelect = 0;
  bool showSearchDetailPanel = false;
  double searchDetailPanelHeight = 3 * (RowWidget.rowHeight + RowWidget.dividerHeight);

  String searchKey = '';

  /// 注意：这是 [options] 的下标，不是 bookId。bookId 在 `options[bookSelect].value` 里。
  RxInt bookSelect = 0.obs;

  List<String> sortOptions = [];
  List<String> progressOptions = [];
  List<String> nextMonthOptions = [];
  List<int> progress = [];
  List<int> nextMonth = [];

  /// 列表骨架 + 正文窗口。以前这里是一整份 `List<VerseShow>`（全课堂的正文常驻内存）。
  late final ShowWindow<VerseShow> window = ShowWindow<VerseShow>(
    fetch: VerseQuery.byIds,
    idOf: (row) => row.verseId,
    onLoaded: () => parentLogic.update([ViewLogicVerseList.bodyId]),
  );

  late HistoryList historyList = HistoryList<T>(parentLogic);
  final T parentLogic;
  VoidCallback onChapterModified;

  /// 筛选下拉框的原料：书本只要 id/名字/排序，章节只要每本书有哪几章。都不带正文。
  List<BookBrief> books;
  Map<int, List<int>> chapterIndexesByBook;

  /// 内容被改过就把窗口里那份正文作废重取。以前是 DAO 顺手 patch 全局缓存，
  /// 现在正文是我们自己按需取的副本，得自己失效。
  final SubList contentSub = [];

  double baseBodyViewHeight = 0;
  int? selectVerseKeyId;

  ViewLogicVerseList({
    required this.parentLogic,
    required this.books,
    required this.chapterIndexesByBook,
    required this.onChapterModified,
    required this.selectVerseKeyId,
    required this.onNext,
    required super.onSearchUnfocus,
    int? initBookIdSelect,
    int? initChapterSelect,
  }) {
    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        tryUpdateDetailSearchPanel(true);
      } else {
        tryUpdateDetailSearchPanel(false);
      }
    });
    searchController.addListener(() {
      search.value = searchController.text;
      trySearch();
    });
    contentSub.on([EventTopic.updateVerseContent, EventTopic.updateVerseProgress, EventTopic.reimportBook], (_) {
      window.invalidate();
      parentLogic.update([ViewLogicVerseList.bodyId]);
    });

    sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    collectData();

    if (initBookIdSelect != null) {
      // 找不到（比如那本书被停用了）就退回"全部"，别留 -1 当下标
      bookSelect.value = options.indexWhere((opt) => opt.value == initBookIdSelect).clamp(0, options.length - 1);
      if (bookSelect.value < options.length) {
        final selectedBook = options[bookSelect.value];
        if (initChapterSelect != null) {
          if (initChapterSelect + 1 < selectedBook.next.length) {
            chapterSelect.value = initChapterSelect + 1;
          }
        }
      }
    }
  }

  String genSearchKey() {
    return '${bookSelect.value},${chapterSelect.value},$progressSelect,$nextMonthSelect,$selectedSortIndex,${search.value}';
  }

  void scrollTo(int selectVerseKeyId) {
    var index = window.indexOfId(selectVerseKeyId);
    if (index >= 0) {
      itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> refresh() async {
    books = await BookBriefHelp.loadEnabled(Classroom.curr);
    chapterIndexesByBook = await ChapterQuery.chapterIndexesByBook(Classroom.curr);
    collectData();
    await loadValueOptions();
    await trySearch(force: true);
  }

  /// 把界面上的筛选项翻成 SQL 条件。
  Future<VerseFilter> buildFilter() async {
    int? bookId;
    int? chapterIndex;
    if (bookSelect.value != 0) {
      if (bookSelect.value < options.length) {
        final selectedBook = options[bookSelect.value];
        bookId = selectedBook.value;
        if (chapterSelect.value != 0) {
          if (chapterSelect.value < selectedBook.next.length) {
            chapterIndex = selectedBook.next[chapterSelect.value].value;
          } else {
            // 选中的章节已经不存在了，退回"这本书全部"
            chapterSelect.value = 0;
          }
        }
      } else {
        bookSelect.value = 0;
      }
    }
    List<int>? verseIds;
    if (search.value.isNotEmpty) {
      // 有 FTS5 走全文索引，没有就退回 SQL LIKE（和以前内存里 contains 原始 JSON 串等价）
      if (VerseSearchIndex.ftsAvailable) {
        verseIds = await VerseSearchIndex.search(Classroom.curr, search.value);
      } else {
        verseIds = await VerseQuery.searchIdsByLike(Classroom.curr, search.value);
      }
    }
    return VerseFilter(
      classroomId: Classroom.curr,
      bookId: bookId,
      chapterIndex: chapterIndex,
      progress: progressSelect != 0 && progressSelect < progress.length ? progress[progressSelect] : null,
      learnMonth: nextMonthSelect != 0 && nextMonthSelect < nextMonth.length ? nextMonth[nextMonthSelect] : null,
      verseIds: verseIds,
      sortBy: sortByOf(sortOptionKeys[selectedSortIndex]),
    );
  }

  @override
  Future<void> trySearch({force = false}) async {
    String newSearchKey = genSearchKey();
    if (!force && newSearchKey == searchKey) {
      return;
    }
    searchKey = newSearchKey;
    window.reset(await VerseQuery.queryIds(await buildFilter()));
    parentLogic.update([ViewLogicVerseList.bodyId]);
  }

  Future<void> delete({required VerseShow verse}) async {
    await showOverlay(() async {
      bool ok = await Db().db.verseDao.delete(verse.verseId);
      if (!ok) {
        return false;
      }
      trySearch(force: true);
    }, I18nKey.labelDeleting.tr);
    Snackbar.show(I18nKey.labelDeleted.tr);
    Get.back();
  }

  Future<void> addFirst() async {
    if (bookSelect.value > 0 && chapterSelect.value > 0) {
      await showOverlay(() async {
        var classroomId = Classroom.curr;
        var book = await Db().db.bookDao.getById(options[bookSelect.value].value);
        if (book == null || book.classroomId != classroomId) {
          Snackbar.show(I18nKey.labelNoContent.tr);
          return;
        }
        int chapterIndex = chapterSelect.value - 1;
        var chapter = await Db().db.chapterDao.one(book.id!, chapterIndex);
        if (chapter == null) {
          Snackbar.show(I18nKey.labelDataAnomaly.tr);
          return;
        }

        await Db().db.verseDao.addFirstVerse(book.id!, chapter.id!, chapterIndex);

        trySearch(force: true);
      }, I18nKey.labelAdding.tr);
      Snackbar.show(I18nKey.labelAddSuccess.tr);
    }
  }

  Future<void> copy({required VerseShow verse, required bool below, bool? last}) async {
    await showOverlay(() async {
      int verseIndex = verse.verseIndex;
      if (below) {
        verseIndex++;
      }
      if (last != null && last && below) {
        var newVerse = await MediaRangeHelper.improveLastCopyContent(verse);
        if (newVerse != null) {
          verse = newVerse;
        }
      }
      int verseId = await Db().db.verseDao.addVerse(verse, verseIndex);
      if (verseId == 0) {
        return;
      }
      trySearch(force: true);
    }, I18nKey.labelCopying.tr);
    Snackbar.show(I18nKey.labelCopied.tr);
    Get.back();
  }

  void tryUpdateDetailSearchPanel(bool newShow) {
    if (showSearchDetailPanel != newShow) {
      showSearchDetailPanel = newShow;
      parentLogic.update([ViewLogicVerseList.bodyId]);
    }
  }

  @override
  Widget show({
    bool focus = true,
    required double width,
    required double height,
  }) {
    // for height
    baseBodyViewHeight = height;
    collectData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (focus) {
        searchFocusNode.requestFocus();
      }
      // 必须等骨架 id 取回来再定位 —— trySearch 现在是查库，不是同步过滤
      await trySearch();
      if (selectVerseKeyId != null) {
        scrollTo(selectVerseKeyId!);
      }
    });
    return GetBuilder<T>(
      id: ViewLogicVerseList.bodyId,
      builder: (_) {
        Widget searchDetailPanel = const SizedBox.shrink();
        if (showSearchDetailPanel) {
          searchDetailPanel = Container(
            height: searchDetailPanelHeight,
            width: width,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                RowWidget.buildCascadeCupertinoPicker(
                  head: [
                    OptionHead(title: I18nKey.labelBookFn.tr, value: bookSelect),
                    OptionHead(title: I18nKey.labelChapterName.tr, value: chapterSelect),
                  ],
                  body: options,
                  changed: (index) {
                    trySearch();
                  },
                ),
                RowWidget.buildCupertinoPicker(
                  title: I18nKey.labelProgress.tr,
                  options: progressOptions,
                  value: progressSelect,
                  changed: (index) {
                    progressSelect = index;
                    trySearch();
                  },
                ),
                RowWidget.buildDividerWithoutColor(),
                RowWidget.buildCupertinoPicker(
                  title: I18nKey.labelMonth.tr,
                  options: nextMonthOptions,
                  value: nextMonthSelect,
                  changed: (index) {
                    nextMonthSelect = index;
                    trySearch();
                  },
                ),
                RowWidget.buildDividerWithoutColor(),
                RowWidget.buildCupertinoPicker(
                  title: I18nKey.labelSortBy.tr,
                  options: sortOptions,
                  value: selectedSortIndex,
                  changed: (index) {
                    selectedSortIndex = index;
                    // 排序也是 SQL 的 ORDER BY，走一遍 trySearch 重取骨架
                    trySearch();
                  },
                  pickWidth: 210.w,
                ),
                RowWidget.buildDividerWithoutColor(),
              ],
            ),
          );
        }
        Widget body = const SizedBox.shrink();

        if (!window.isEmpty) {
          body = ScrollablePositionedList.builder(
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
            itemCount: window.length,
            itemBuilder: (context, index) {
              // 正文还没落到窗口里就先占个位，窗口补齐后 onLoaded 会触发重画
              final verse = window.at(index);
              if (verse == null) {
                return const SizedBox(height: 96);
              }
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              onNext(window.ids, index);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                versePos(bookNames[verse.bookId] ?? '', verse.chapterIndex, verse.verseIndex),
                                style: const TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ),
                          SizedBox(height: 8, width: width),
                          ExpandableText(
                            title: I18nKey.labelVerseName.tr,
                            text: ': ${verse.verseContent}',
                            version: verse.verseContentVersion,
                            limit: 60,
                            style: const TextStyle(fontSize: 14),
                            selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                            versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                            selectText: search.value,
                            onIcon: () {
                              onEdit(verse);
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    editProgressWithMsgBox(verse);
                                  },
                                  child: Text(
                                    '${I18nKey.labelProgress.tr}: ${verse.progress}',
                                    style: const TextStyle(fontSize: 12, color: Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    editProgressWithMsgBox(verse);
                                  },
                                  child: Text(
                                    '${I18nKey.labelSetNextLearnDate.tr}: ${verse.learnDate.format()}',
                                    style: const TextStyle(fontSize: 12, color: Colors.green),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              onTap: () {
                                onEdit(verse);
                              },
                              child: Text(I18nKey.edit.tr),
                            ),
                            PopupMenuItem<String>(
                              onTap: () {
                                MsgBox.myDialog(
                                  title: I18nKey.labelTips.tr,
                                  content: MsgBox.content(I18nKey.labelCopyToWhere.tr),
                                  action: MsgBox.buttonsWithDivider(
                                    buttons: [
                                      MsgBox.button(
                                        text: I18nKey.btnCancel.tr,
                                        onPressed: () {
                                          Get.back();
                                        },
                                      ),
                                      MsgBox.button(
                                        text: I18nKey.btnAbove.tr,
                                        onPressed: () => copy(verse: verse, below: false),
                                      ),
                                      MsgBox.button(
                                        text: I18nKey.btnBelow.tr,
                                        onPressed: () => copy(verse: verse, below: true, last: index + 1 == window.length),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(I18nKey.btnCopy.tr),
                            ),
                            PopupMenuItem<String>(
                              onTap: () {
                                MsgBox.yesOrNo(
                                  title: I18nKey.labelWarning.tr,
                                  desc: I18nKey.labelDeleteVerse.tr,
                                  yes: () => delete(verse: verse),
                                );
                              },
                              child: Text(I18nKey.btnDelete.tr),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        } else if (bookSelect.value > 0 && chapterSelect.value > 0 && search.value.isEmpty && progressSelect == 0 && nextMonthSelect == 0) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      style: TextStyle(color: Theme.of(Get.context!).colorScheme.onSurface),
                      text: I18nKey.labelVerseTipForAddingContent.trArgs(["${options[bookSelect.value].label}-${chapterSelect.value}"]),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: IconButton(
                        onPressed: addFirst,
                        icon: const Icon(Icons.add),
                        padding: EdgeInsets.zero, // Optional: removes extra padding
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            searchDetailPanel,
            SizedBox(
              height: getBodyViewHeight(),
              width: width,
              child: body,
            ),
          ],
        );
      },
    );
  }

  void onEdit(VerseShow verse) async {
    searchFocusNode.unfocus();
    var contentM = jsonDecode(verse.verseContent);
    var content = const JsonEncoder.withIndent(' ').convert(contentM);
    await Nav.editor.push(
      arguments: EditorArgs(
        title: I18nKey.labelVerseName.tr,
        value: content,
        save: (str) async {
          await Db().db.verseDao.updateVerseContent(verse.verseId, str);
          parentLogic.update([ViewLogicVerseList.bodyId]);
        },
        onHistory: () async {
          List<VerseContentVersion> historyData = await Db().db.verseContentVersionDao.list(verse.verseId);
          await historyList.show(historyData, focus: true.obs);
        },
        contentChangeTopics: [EventTopic.reimportBook],
        getContent: () async {
          var c = await Db().db.scheduleDao.getVerseShowById(verse.verseId);
          if (c == null) {
            return '';
          }
          var contentM = jsonDecode(c.verseContent);
          return JsonEncoder.withIndent(' ').convert(contentM);
        },
      ),
    );
  }

  void updateOptions() {
    options = [];
    final List<OptionBody> bookOptions = [];

    for (var book in books) {
      final sortedIndices = (chapterIndexesByBook[book.bookId] ?? []).toSet().toList()..sort();
      sortedIndices.insert(0, -1);

      final chapterOptions = sortedIndices.map((k) {
        return OptionBody(
          label: (k == -1) ? I18nKey.labelAll.tr : '${k + 1}',
          value: k,
          next: [],
        );
      }).toList();

      bookOptions.add(
        OptionBody(
          // label 只给界面看，value 才是程序认的 bookId
          label: book.name,
          value: book.bookId,
          next: chapterOptions,
        ),
      );
    }

    options.add(
      OptionBody(
        label: I18nKey.labelAll.tr,
        value: -1,
        next: [
          OptionBody(
            label: I18nKey.labelAll.tr,
            value: -1,
            next: [],
          ),
        ],
      ),
    );

    options.addAll(bookOptions);
  }

  void collectData() {
    bookNames = {for (var book in books) book.bookId: book.name};
    updateOptions();
    rebuildValueOptions();
  }

  /// 进度、下次学习月这两个下拉框的取值范围。
  ///
  /// 以前是从"当前这一屏已加载的句子"里现算的 —— 一旦按进度筛过，下拉框就只剩
  /// 选中的那一档了。现在让 SQL 对整个课堂 DISTINCT，取值范围稳定且不依赖已加载内容。
  Future<void> loadValueOptions() async {
    progress = await VerseQuery.distinctProgress(Classroom.curr);
    nextMonth = await VerseQuery.distinctLearnMonth(Classroom.curr);
    rebuildValueOptions();
    parentLogic.update([ViewLogicVerseList.bodyId]);
  }

  void rebuildValueOptions() {
    progress = progress.where((e) => e != -1).toList();
    nextMonth = nextMonth.where((e) => e != -1).toList();
    progress.sort();
    progress.insert(0, -1);
    progressOptions = progress.map((k) {
      if (k == -1) {
        return I18nKey.labelAll.tr;
      }
      return k.toString();
    }).toList();

    nextMonth.sort();
    nextMonth.insert(0, -1);
    nextMonthOptions = nextMonth.map((k) {
      if (k == -1) {
        return I18nKey.labelAll.tr;
      }
      return '${k.toString().substring(0, 4)}-${k.toString().substring(4, 6)}';
    }).toList();
  }

  /// 排序不再在内存里做，交给 SQL 的 ORDER BY。
  static VerseSortBy sortByOf(I18nKey key) {
    switch (key) {
      case I18nKey.labelSortProgressAsc:
        return VerseSortBy.progressAsc;
      case I18nKey.labelSortProgressDesc:
        return VerseSortBy.progressDesc;
      case I18nKey.labelSortPositionDesc:
        return VerseSortBy.positionDesc;
      case I18nKey.labelSortNextLearnDateAsc:
        return VerseSortBy.learnDateAsc;
      case I18nKey.labelSortNextLearnDateDesc:
        return VerseSortBy.learnDateDesc;
      default:
        return VerseSortBy.positionAsc;
    }
  }

  double getBodyViewHeight() {
    double ret = baseBodyViewHeight;
    if (showSearchDetailPanel) {
      ret = ret - searchDetailPanelHeight;
    }
    return ret;
  }

  Future<void> editProgressWithMsgBox(VerseShow verse) async {
    var nextTimeForWarning = await Db().db.scheduleDao.intKv(Classroom.curr, CrK.nextTimeForSettingLearningProgressWarning) ?? 0;
    var now = DateTime.now();
    if (nextTimeForWarning <= now.millisecondsSinceEpoch) {
      MsgBox.yesOrNo(
        title: I18nKey.labelTips.tr,
        desc: I18nKey.labelSettingLearningProgressWarning.tr,
        yesBtnTitle: I18nKey.btnContinue.tr,
        yes: () async {
          var after3Days = now.add(const Duration(days: 3)).millisecondsSinceEpoch.toString();
          await Db().db.scheduleDao.insertKv(CrKv(Classroom.curr, CrK.nextTimeForSettingLearningProgressWarning, after3Days));
          Get.back();
          await editProgress(verse);
        },
      );
    } else {
      await editProgress(verse);
    }
  }

  Future<void> editProgress(VerseShow verse) async {
    EditProgress.show(
      verse.verseId,
      warning: I18nKey.labelSettingLearningProgressWarning.tr,
      title: I18nKey.btnOk.tr,
      callback: (p, n) async {
        await Db().db.scheduleDao.jumpDirectly(verse.verseId, p, n);
        Get.back();
        parentLogic.update([ViewLogicVerseList.bodyId]);
      },
    );
  }

  @override
  dispose() {
    contentSub.off();
    searchController.dispose();
    searchFocusNode.dispose();
  }

  void setBookSelectById(int bookId) {
    bookSelect.value = options.indexWhere((opt) => opt.value == bookId).clamp(0, options.length - 1);
  }
}
