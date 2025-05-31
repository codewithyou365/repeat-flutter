import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/logic/widget/editor.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'view_logic.dart';

class ViewLogicBookList<T extends GetxController> extends ViewLogic {
  static const String bodyId = "BookList.bodyId";
  late HistoryList historyList = HistoryList<T>(parentLogic);

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  double searchDetailPanelHeight = 2 * (RowWidget.rowHeight + RowWidget.dividerHeight);
  final RxString search = RxString("");
  final T parentLogic;
  List<BookShow> originalBookShow;
  List<BookShow> bookShow = [];

  bool showSearchDetailPanel = false;
  RxInt contentNameSelect = 0.obs;
  String searchKey = '';

  // for collect search data, and missing book
  int missingBookOffset = -1;
  List<String> contentNameOptions = [];
  List<String> sortOptions = [];
  RxInt selectedSortIndex = 0.obs;
  List<I18nKey> sortOptionKeys = [
    I18nKey.labelSortPositionAsc,
    I18nKey.labelSortPositionDesc,
  ];

  double baseBodyViewHeight = 0;

  ViewLogicBookList({
    required VoidCallback onSearchUnfocus,
    required this.originalBookShow,
    required this.parentLogic,
    String? initContentNameSelect,
  }) : super(onSearchUnfocus: onSearchUnfocus) {
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

    searchKey = genSearchKey();
    bookShow = List.from(originalBookShow);

    // for sorting and content
    sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(bookShow, sortOptionKeys[selectedSortIndex.value]);

    collectData(
      contentNameOptions,
      bookShow,
    );
    if (initContentNameSelect != null) {
      contentNameSelect.value = contentNameOptions.indexOf(initContentNameSelect);
    }
  }

  void tryUpdateDetailSearchPanel(bool newShow) {
    if (showSearchDetailPanel != newShow) {
      showSearchDetailPanel = newShow;
      parentLogic.update([ViewLogicBookList.bodyId]);
    }
  }

  String genSearchKey() {
    return '${contentNameSelect.value},${search.value}';
  }

  @override
  void trySearch({bool force = false}) {
    String newSearchKey = genSearchKey();
    if (!force && newSearchKey == searchKey) {
      return;
    }
    searchKey = newSearchKey;
    if (search.value.isNotEmpty || contentNameSelect.value != 0) {
      bookShow = originalBookShow.where((e) {
        bool ret = true;
        if (ret && search.value.isNotEmpty) {
          ret = e.bookContent.contains(search.value);
        }
        if (ret && contentNameSelect.value != 0) {
          ret = e.name == contentNameOptions[contentNameSelect.value];
        }
        return ret;
      }).toList();
    } else {
      bookShow = List.from(originalBookShow);
    }
    sort(bookShow, sortOptionKeys[selectedSortIndex.value]);

    parentLogic.update([ViewLogicBookList.bodyId]);
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
          var list = bookShow;

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
                    I18nKey.labelContent.tr,
                    contentNameOptions,
                    contentNameSelect,
                    changed: (index) {
                      contentNameSelect.value = index;
                      trySearch();
                    },
                  ),
                  RowWidget.buildDividerWithoutColor(),
                  RowWidget.buildCupertinoPicker(
                    I18nKey.labelSortBy.tr,
                    sortOptions,
                    selectedSortIndex,
                    changed: (index) {
                      selectedSortIndex.value = index;
                      I18nKey key = sortOptionKeys[index];
                      sort(bookShow, key);
                      parentLogic.update([ViewLogicBookList.bodyId]);
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
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final book = list[index];
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    book.toPos(),
                                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                                  ),
                                ),
                                SizedBox(height: 8, width: width),
                                ExpandableText(
                                  title: I18nKey.labelBook.tr,
                                  text: ': ${book.bookContent}',
                                  version: book.bookContentVersion,
                                  limit: 60,
                                  style: const TextStyle(fontSize: 14),
                                  selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                                  versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                  selectText: search.value,
                                  onEdit: () {
                                    searchFocusNode.unfocus();
                                    var contentM = jsonDecode(book.bookContent);
                                    var content = const JsonEncoder.withIndent(' ').convert(contentM);
                                    Editor.show(
                                      Get.context!,
                                      I18nKey.labelBook.tr,
                                      content,
                                      (str) async {
                                        await Db().db.contentDao.updateBookContent(book.bookId, str);
                                        parentLogic.update([ViewLogicBookList.bodyId]);
                                      },
                                      qrPagePath: Nav.gsCrContentScan.path,
                                      onHistory: () {
                                        historyList.show(TextVersionType.bookContent, book.bookId);
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        });
  }

  void collectData(
    List<String> contentName,
    List<BookShow> bookShow,
  ) {
    for (int i = 0; i < bookShow.length; i++) {
      var v = bookShow[i];
      if (!contentName.contains(v.name)) {
        contentName.add(v.name);
      }
    }
    contentName.insert(0, I18nKey.labelAll.tr);
  }

  sort(List<BookShow> bookShow, I18nKey key) {
    switch (key) {
      case I18nKey.labelSortPositionAsc:
        bookShow.sort((a, b) => a.toSort().compareTo(b.toSort()));
        break;
      case I18nKey.labelSortPositionDesc:
        bookShow.sort((a, b) => b.toSort().compareTo(a.toSort()));
        break;
      default:
        break;
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
  dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
  }
}
