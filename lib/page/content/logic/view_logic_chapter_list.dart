import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/chapter_content_version.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/db/query/chapter_query.dart';
import 'package:repeat_flutter/db/query/show_window.dart';
import 'package:repeat_flutter/logic/book_brief_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_brief.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/model/verse_pos.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'view_logic.dart';

class ViewLogicChapterList<T extends GetxController> extends ViewLogic {
  static const String bodyId = "ChapterList.bodyId";
  late HistoryList historyList = HistoryList<T>(parentLogic);
  final void Function(ChapterShow chapterShow) onNext;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  double searchDetailPanelHeight = 3 * (RowWidget.rowHeight + RowWidget.dividerHeight);

  final RxString search = RxString("");
  final T parentLogic;

  /// 筛选下拉框的原料：书本只要 id/名字/排序，章节只要每本书有哪几章。都不带正文。
  List<BookBrief> books;
  Map<int, List<int>> chapterIndexesByBook;

  /// 列表骨架 + 正文窗口。以前这里是一整份 `List<ChapterShow>`（全课堂章节正文常驻内存）。
  late final ShowWindow<ChapterShow> window = ShowWindow<ChapterShow>(
    fetch: ChapterQuery.byIds,
    idOf: (row) => row.chapterId,
    onLoaded: () => parentLogic.update([ViewLogicChapterList.bodyId]),
  );

  VoidCallback onChapterModified;

  /// bookId -> 书名。**只给界面显示用**，过滤/分组一律拿 bookId 比。
  Map<int, String> bookNames = {};

  bool showSearchDetailPanel = false;

  /// 注意：这是 [options] 的下标，不是 bookId。bookId 在 `options[bookSelect].value` 里。
  RxInt bookSelect = 0.obs;
  RxInt chapterSelect = 0.obs;
  String searchKey = '';
  List<OptionBody> options = [];

  // for collect search data, and missing chapter
  int missingChapterOffset = -1;
  List<String> sortOptions = [];
  int selectedSortIndex = 0;
  List<I18nKey> sortOptionKeys = [
    I18nKey.labelSortPositionAsc,
    I18nKey.labelSortPositionDesc,
  ];

  /// 内容被改过就把窗口里那份正文作废重取。以前是 DAO 顺手 patch 全局缓存，
  /// 现在正文是我们自己按需取的副本，得自己失效。
  final SubList contentSub = [];

  double baseBodyViewHeight = 0;

  ViewLogicChapterList({
    required this.onChapterModified,
    required this.books,
    required this.chapterIndexesByBook,
    required this.parentLogic,
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
    contentSub.on([EventTopic.updateChapterContent, EventTopic.reimportBook], (_) {
      window.invalidate();
      parentLogic.update([ViewLogicChapterList.bodyId]);
    });

    // searchKey 故意留空：列表数据现在要查库才有，第一次 trySearch 必须真的跑一遍，
    // 不能因为"筛选条件没变"就跳过（以前构造时已经把全量数据塞进列表了才可以跳）。

    // for sorting and content
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

  void tryUpdateDetailSearchPanel(bool newShow) {
    if (showSearchDetailPanel != newShow) {
      showSearchDetailPanel = newShow;
      parentLogic.update([ViewLogicChapterList.bodyId]);
    }
  }

  String genSearchKey() {
    return '$bookSelect,$chapterSelect,$selectedSortIndex,${search.value}';
  }

  ChapterFilter buildFilter() {
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
    return ChapterFilter(
      classroomId: Classroom.curr,
      bookId: bookId,
      chapterIndex: chapterIndex,
      keyword: search.value.isEmpty ? null : search.value,
      asc: sortOptionKeys[selectedSortIndex] != I18nKey.labelSortPositionDesc,
    );
  }

  @override
  Future<void> trySearch({bool force = false}) async {
    String newSearchKey = genSearchKey();
    if (!force && newSearchKey == searchKey) {
      return;
    }
    searchKey = newSearchKey;
    window.reset(await ChapterQuery.queryIds(buildFilter()));
    parentLogic.update([ViewLogicChapterList.bodyId]);
  }

  Future<void> refresh() async {
    books = await BookBriefHelp.loadEnabled(Classroom.curr);
    chapterIndexesByBook = await ChapterQuery.chapterIndexesByBook(Classroom.curr);
    onChapterModified();
    collectData();
    await trySearch(force: true);
  }

  Future<void> delete({required ChapterShow chapter}) async {
    bool success = await showOverlay<bool>(() async {
      bool ok = await Db().db.chapterDao.deleteChapter(chapter.chapterId);
      if (!ok) {
        return false;
      }
      refresh();
      return true;
    }, I18nKey.labelDeleting.tr);
    if (success) {
      Snackbar.show(I18nKey.labelDeleted.tr);
    }
    Get.back();
  }

  Future<void> addFirst() async {
    bool success = false;
    if (bookSelect.value > 0) {
      success = await showOverlay<bool>(() async {
        var classroomId = Classroom.curr;
        var book = await Db().db.bookDao.getById(options[bookSelect.value].value);
        if (book == null || book.classroomId != classroomId) {
          Snackbar.show(I18nKey.labelNoContent.tr);
          return false;
        }
        var chapterCount = await Db().db.chapterDao.count(book.id!) ?? 0;
        if (chapterCount == 0) {
          await Db().db.chapterDao.addFirstChapter(book.id!);
          refresh();
        }
        return true;
      }, I18nKey.labelCopying.tr);
    }
    if (success) {
      Snackbar.show(I18nKey.labelAddSuccess.tr);
    }
  }

  Future<void> copy({required ChapterShow chapter, required bool below}) async {
    bool success = await showOverlay<bool>(() async {
      int chapterIndex = chapter.chapterIndex;
      if (below) {
        chapterIndex++;
      }
      var ok = await Db().db.chapterDao.addChapter(chapter, chapterIndex);
      if (!ok) {
        return false;
      }
      refresh();
      return true;
    }, I18nKey.labelCopying.tr);
    if (success) {
      Snackbar.show(I18nKey.labelCopied.tr);
    }
    Get.back();
  }

  void setBookSelectById(int bookId) {
    bookSelect.value = options.indexWhere((opt) => opt.value == bookId).clamp(0, options.length - 1);
  }

  @override
  Widget show({
    bool focus = true,
    required double width,
    required double height,
  }) {
    baseBodyViewHeight = height;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focus) {
        searchFocusNode.requestFocus();
      }
      trySearch();
    });

    return GetBuilder<T>(
      id: ViewLogicChapterList.bodyId,
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
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 3),
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
              final chapter = window.at(index);
              if (chapter == null) {
                return const SizedBox(height: 96);
              }
              return Card(
                color: null,
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
                              onNext(chapter);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                chapterPos(bookNames[chapter.bookId] ?? '', chapter.chapterIndex),
                                style: const TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ),
                          SizedBox(height: 8, width: width),
                          ExpandableText(
                            title: I18nKey.labelChapterName.tr,
                            text: ': ${chapter.chapterContent}',
                            version: chapter.chapterContentVersion,
                            limit: 60,
                            style: const TextStyle(fontSize: 14),
                            selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                            versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                            selectText: search.value,
                            onIcon: () {
                              onEdit(chapter);
                            },
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
                                onEdit(chapter);
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
                                        onPressed: () => copy(chapter: chapter, below: false),
                                      ),
                                      MsgBox.button(
                                        text: I18nKey.btnBelow.tr,
                                        onPressed: () => copy(chapter: chapter, below: true),
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
                                  desc: I18nKey.labelDeleteChapter.tr,
                                  yes: () => delete(chapter: chapter),
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
        } else if (bookSelect.value > 0 && search.value.isEmpty) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      style: TextStyle(color: Theme.of(Get.context!).colorScheme.onSurface),
                      text: I18nKey.labelChapterTipForAddingContent.trArgs([options[bookSelect.value].label]),
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

  void onEdit(ChapterShow chapter) async {
    searchFocusNode.unfocus();
    var contentM = jsonDecode(chapter.chapterContent);
    var content = const JsonEncoder.withIndent(' ').convert(contentM);
    await Nav.editor.push(
      arguments: EditorArgs(
        title: I18nKey.labelChapterName.tr,
        value: content,
        save: (str) async {
          await Db().db.chapterDao.updateChapterContent(chapter.chapterId, str);
          parentLogic.update([ViewLogicChapterList.bodyId]);
        },
        onHistory: () async {
          List<ChapterContentVersion> historyData = await Db().db.chapterContentVersionDao.list(chapter.chapterId);
          await historyList.show(historyData, focus: true.obs);
        },
        contentChangeTopics: [EventTopic.reimportBook],
        getContent: () async {
          var c = await Db().db.chapterDao.getChapterShowById(chapter.chapterId);
          if (c == null) {
            return '';
          }
          var contentM = jsonDecode(c.chapterContent);
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
  }

  double getBodyViewHeight() {
    double ret = baseBodyViewHeight;
    if (showSearchDetailPanel) {
      ret = ret - searchDetailPanelHeight;
    }
    return ret;
  }

  @override
  dispose() {
    contentSub.off();
    searchController.dispose();
    searchFocusNode.dispose();
  }
}
