import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book_content_version.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/db/query/book_query.dart';
import 'package:repeat_flutter/db/query/show_window.dart';
import 'package:repeat_flutter/logic/book_brief_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_brief.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart' show MsgBox;
import 'package:repeat_flutter/widget/overlay/overlay.dart' show showOverlay;
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'view_logic.dart';

class ViewLogicBookList<T extends GetxController> extends ViewLogic {
  static const String bodyId = "BookList.bodyId";
  late HistoryList historyList = HistoryList<T>(parentLogic);
  final void Function(BookShow bookShow) onNext;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  double searchDetailPanelHeight = 2 * (RowWidget.rowHeight + RowWidget.dividerHeight);
  final RxString search = RxString("");
  final T parentLogic;
  /// 筛选下拉框的原料：只要 id/名字/排序，不带正文。
  List<BookBrief> books;

  /// 列表骨架 + 正文窗口。书本不多，但每本 content 可能挺大（'d' 下载列表），一样按需取。
  late final ShowWindow<BookShow> window = ShowWindow<BookShow>(
    fetch: BookQuery.byIds,
    idOf: (row) => row.bookId,
    onLoaded: () => parentLogic.update([ViewLogicBookList.bodyId]),
  );

  bool showSearchDetailPanel = false;
  int bookSelect = 0;
  String searchKey = '';

  // for collect search data, and missing book
  int missingBookOffset = -1;
  /// 下拉框的显示文字。**只给界面看**，筛选认的是同下标的 [bookOptionIds]。
  List<String> bookOptions = [];

  /// 和 [bookOptions] 一一对应的 bookId，下标 0（"全部"）是 -1。
  List<int> bookOptionIds = [];
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

  ViewLogicBookList({
    required this.books,
    required this.parentLogic,
    required this.onNext,
    required super.onSearchUnfocus,
    int? initBookIdSelect,
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
    contentSub.on([EventTopic.updateBookContent, EventTopic.reimportBook], (_) {
      window.invalidate();
      parentLogic.update([ViewLogicBookList.bodyId]);
    });

    // searchKey 故意留空：列表数据现在要查库才有，第一次 trySearch 必须真的跑一遍，
    // 不能因为"筛选条件没变"就跳过（以前构造时已经把全量数据塞进列表了才可以跳）。

    // for sorting and content
    sortOptions = sortOptionKeys.map((key) => key.tr).toList();

    collectData();

    if (initBookIdSelect != null) {
      // 找不到（比如那本书被停用了）就退回"全部"，别留 -1 当下标
      bookSelect = bookOptionIds.indexOf(initBookIdSelect).clamp(0, bookOptionIds.length - 1);
    }
  }

  void tryUpdateDetailSearchPanel(bool newShow) {
    if (showSearchDetailPanel != newShow) {
      showSearchDetailPanel = newShow;
      parentLogic.update([ViewLogicBookList.bodyId]);
    }
  }

  String genSearchKey() {
    return '$bookSelect,$selectedSortIndex,${search.value}';
  }

  BookFilter buildFilter() {
    int? bookId;
    if (bookSelect != 0) {
      if (bookSelect < bookOptionIds.length) {
        bookId = bookOptionIds[bookSelect];
      } else {
        bookSelect = 0;
      }
    }
    return BookFilter(
      classroomId: Classroom.curr,
      bookId: bookId,
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
    window.reset(await BookQuery.queryIds(buildFilter()));
    parentLogic.update([ViewLogicBookList.bodyId]);
  }

  Future<void> refresh() async {
    books = await BookBriefHelp.loadEnabled(Classroom.curr);
    collectData();
    await trySearch(force: true);
  }

  Future<void> delete({required BookShow book}) async {
    bool success = await showOverlay<bool>(() async {
      await Db().db.bookDao.deleteBook(book.bookId);
      return true;
    }, I18nKey.labelDeleting.tr);
    if (success) {
      Snackbar.show(I18nKey.labelDeleted.tr);
    }
    Get.back();
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
      id: ViewLogicBookList.bodyId,
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
                RowWidget.buildCupertinoPicker(
                  title: I18nKey.labelBookFn.tr,
                  options: bookOptions,
                  value: bookSelect,
                  changed: (index) {
                    bookSelect = index;
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
        return Column(
          children: [
            searchDetailPanel,
            SizedBox(
              height: getBodyViewHeight(),
              width: width,
              child: ScrollablePositionedList.builder(
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                itemCount: window.length,
                itemBuilder: (context, index) {
                  // 正文还没落到窗口里就先占个位，窗口补齐后 onLoaded 会触发重画
                  final book = window.at(index);
                  if (book == null) {
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
                                  onNext(book);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    book.name,
                                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8, width: width),
                              ExpandableText(
                                title: I18nKey.labelBookFn.tr,
                                text: ': ${book.bookContent}',
                                version: book.bookContentVersion,
                                limit: 60,
                                style: const TextStyle(fontSize: 14),
                                selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                                versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                selectText: search.value,
                                onIcon: () {
                                  onEdit(book);
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
                                    onEdit(book);
                                  },
                                  child: Text(I18nKey.edit.tr),
                                ),
                                PopupMenuItem<String>(
                                  onTap: () {
                                    MsgBox.yesOrNo(
                                      title: I18nKey.labelWarning.tr,
                                      desc: I18nKey.labelDeleteBook.trArgs([book.name]),
                                      yes: () => delete(book: book),
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
              ),
            ),
          ],
        );
      },
    );
  }

  void onEdit(BookShow book) async {
    searchFocusNode.unfocus();
    var contentM = jsonDecode(book.bookContent);
    var content = const JsonEncoder.withIndent(' ').convert(contentM);
    await Nav.editor.push(
      arguments: EditorArgs(
        title: I18nKey.labelBookFn.tr,
        value: content,
        save: (str) async {
          await Db().db.bookDao.updateBookContent(book.bookId, str);
          parentLogic.update([ViewLogicBookList.bodyId]);
        },
        onHistory: () async {
          List<BookContentVersion> historyData = await Db().db.bookContentVersionDao.list(book.bookId);
          await historyList.show(historyData, focus: true.obs);
        },
        contentChangeTopics: [EventTopic.reimportBook],
        getContent: () async {
          var c = await Db().db.bookDao.getBookShowById(book.bookId);
          if (c == null) {
            return '';
          }
          var contentM = jsonDecode(c.bookContent);
          return JsonEncoder.withIndent(' ').convert(contentM);
        },
      ),
    );
  }

  void collectData() {
    bookOptions = [I18nKey.labelAll.tr];
    bookOptionIds = [-1];
    for (var book in books) {
      bookOptionIds.add(book.bookId);
      bookOptions.add(book.name);
    }
  }

  double getBodyViewHeight() {
    double ret = baseBodyViewHeight;
    if (showSearchDetailPanel) {
      ret = ret - searchDetailPanelHeight;
    }
    return ret;
  }

  @override
  void dispose() {
    contentSub.off();
    searchController.dispose();
    searchFocusNode.dispose();
  }
}
