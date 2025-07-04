import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/chapter_content_version.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/chapter_key.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/logic/widget/editor.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
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

  double missPanelHeight = RowWidget.rowHeight + RowWidget.dividerHeight;
  final RxString search = RxString("");
  final T parentLogic;
  List<BookShow> originalBookShow;
  List<ChapterShow> originalChapterShow;
  List<ChapterShow> chapterShow = [];
  VoidCallback onChapterModified;
  final Future<void> Function()? removeWarning;

  bool showSearchDetailPanel = false;
  RxInt bookSelect = 0.obs;
  RxInt chapterSelect = 0.obs;
  String searchKey = '';
  List<OptionBody> options = [];

  // for collect search data, and missing chapter
  int missingChapterOffset = -1;
  List<int> missingChapterIndex = [];
  List<String> sortOptions = [];
  RxInt selectedSortIndex = 0.obs;
  List<I18nKey> sortOptionKeys = [
    I18nKey.labelSortPositionAsc,
    I18nKey.labelSortPositionDesc,
  ];

  double baseBodyViewHeight = 0;

  ViewLogicChapterList({
    required this.onChapterModified,
    required this.originalBookShow,
    required this.originalChapterShow,
    required this.parentLogic,
    required this.removeWarning,
    required this.onNext,
    required super.onSearchUnfocus,
    String? initBookNameSelect,
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

    searchKey = genSearchKey();
    chapterShow = List.from(originalChapterShow);

    // for sorting and content
    sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(chapterShow, sortOptionKeys[selectedSortIndex.value]);

    collectData();

    if (initBookNameSelect != null) {
      bookSelect.value = options.indexWhere((opt) => opt.label == initBookNameSelect);
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
    return '${bookSelect.value},${chapterSelect.value},${search.value}';
  }

  @override
  void trySearch({bool force = false}) {
    String newSearchKey = genSearchKey();
    if (!force && newSearchKey == searchKey) {
      return;
    }
    searchKey = newSearchKey;
    if (search.value.isNotEmpty || bookSelect.value != 0 || chapterSelect.value != 0) {
      chapterShow = originalChapterShow.where((e) {
        bool ret = true;
        if (ret && search.value.isNotEmpty) {
          ret = e.chapterContent.contains(search.value);
        }
        if (ret && bookSelect.value != 0) {
          if (bookSelect.value < options.length) {
            final selectedBook = options[bookSelect.value];
            ret = e.bookName == selectedBook.label;
            if (ret && chapterSelect.value != 0) {
              if (chapterSelect.value < selectedBook.next.length) {
                final selectedChapter = selectedBook.next[chapterSelect.value];
                ret = e.chapterIndex == selectedChapter.value;
              } else {
                ret = false;
              }
            }
          } else {
            ret = false;
          }
        }
        return ret;
      }).toList();
    } else {
      chapterShow = List.from(originalChapterShow);
    }
    sort(chapterShow, sortOptionKeys[selectedSortIndex.value]);
    refreshMissingChapterIndex(missingChapterIndex, chapterShow);

    parentLogic.update([ViewLogicChapterList.bodyId]);
  }

  Future<void> refresh(ChapterKey? chapterKey) async {
    if (chapterKey != null) {
      await VerseHelp.getVerses(
        force: true,
        query: QueryChapter(
          bookId: chapterKey.bookId,
          minChapterIndex: chapterKey.chapterIndex,
        ),
      );
    }
    originalChapterShow = await ChapterHelp.getChapters(force: true);
    onChapterModified();
    collectData();
    trySearch(force: true);
    await Get.find<GsCrLogic>().init();
  }

  Future<void> delete({required ChapterShow chapter}) async {
    bool success = await showOverlay<bool>(() async {
      Map<String, dynamic> out = {};
      bool ok = await Db().db.chapterKeyDao.deleteNormalChapter(chapter.chapterKeyId, out);
      if (!ok) {
        return false;
      }
      ChapterKey chapterKey = out['chapterKey'] as ChapterKey;
      await refresh(chapterKey);
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
        var book = await Db().db.bookDao.getBookByName(classroomId, options[bookSelect.value].label);
        if (book == null) {
          Snackbar.show(I18nKey.labelNoContent.tr);
          return false;
        }
        var chapterCount = await Db().db.chapterDao.count(book.id!) ?? 0;
        if (chapterCount == 0) {
          await Db().db.chapterKeyDao.addFirstChapter(book.id!);
          await refresh(null);
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
      Map<String, dynamic> out = {};
      var ok = await Db().db.chapterKeyDao.addChapter(chapter, chapterIndex, out);
      if (!ok) {
        return false;
      }
      ChapterKey chapterKey = out['chapterKey'] as ChapterKey;
      await refresh(chapterKey);
      return true;
    }, I18nKey.labelCopying.tr);
    if (success) {
      Snackbar.show(I18nKey.labelCopied.tr);
    }
    Get.back();
  }

  void setBookSelectByName(String bookName) {
    bookSelect.value = options.indexWhere((opt) => opt.label == bookName);
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
          var list = chapterShow;

          Widget missingPanel = const SizedBox.shrink();
          if (missingChapterIndex.isNotEmpty) {
            missingPanel = SizedBox(
              height: missPanelHeight,
              width: width,
              child: Column(
                children: [
                  RowWidget.buildWidgetsWithTitle(I18nKey.labelFindUnnecessaryChapters.tr, [
                    IconButton(
                        onPressed: () {
                          if (missingChapterOffset - 1 < 0) {
                            missingChapterOffset = 0;
                          } else {
                            missingChapterOffset--;
                          }
                          itemScrollController.scrollTo(
                            index: missingChapterIndex[missingChapterOffset],
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back)),
                    IconButton(
                        onPressed: () {
                          if (missingChapterOffset + 1 >= missingChapterIndex.length) {
                            missingChapterOffset = missingChapterIndex.length - 1;
                          } else {
                            missingChapterOffset++;
                          }
                          itemScrollController.scrollTo(
                            index: missingChapterIndex[missingChapterOffset],
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_forward)),
                  ]),
                  RowWidget.buildDividerWithoutColor(),
                ],
              ),
            );
          }
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
                    I18nKey.labelSortBy.tr,
                    sortOptions,
                    selectedSortIndex,
                    changed: (index) {
                      selectedSortIndex.value = index;
                      I18nKey key = sortOptionKeys[index];
                      sort(chapterShow, key);
                      parentLogic.update([ViewLogicChapterList.bodyId]);
                    },
                    pickWidth: 210.w,
                  ),
                  RowWidget.buildDividerWithoutColor(),
                ],
              ),
            );
          }
          Widget body = const SizedBox.shrink();
          if (list.isNotEmpty) {
            body = ScrollablePositionedList.builder(
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final chapter = list[index];
                return Card(
                  color: chapter.missing ? Colors.red : null,
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
                                  chapter.toPos(),
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
                              onEdit: () {
                                searchFocusNode.unfocus();
                                var contentM = jsonDecode(chapter.chapterContent);
                                var content = const JsonEncoder.withIndent(' ').convert(contentM);
                                Editor.show(
                                  Get.context!,
                                  I18nKey.labelChapterName.tr,
                                  content,
                                  (str) async {
                                    await Db().db.chapterKeyDao.updateChapterContent(chapter.chapterKeyId, str);
                                    parentLogic.update([ViewLogicChapterList.bodyId]);
                                  },
                                  qrPagePath: Nav.scan.path,
                                  onHistory: () async {
                                    List<ChapterContentVersion> historyData = await Db().db.chapterContentVersionDao.list(chapter.chapterKeyId);
                                    await historyList.show(historyData);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (chapter.missing)
                            IconButton(
                              onPressed: () {
                                MsgBox.yesOrNo(
                                  title: I18nKey.labelDelete.tr,
                                  desc: I18nKey.labelDeleteChapter.tr,
                                  yes: () {
                                    showTransparentOverlay(() async {
                                      var ok = await Db().db.chapterKeyDao.deleteAbnormalChapter(chapter.chapterKeyId);
                                      if (ok == false) {
                                        return;
                                      }
                                      ChapterHelp.deleteCache(chapter.chapterKeyId);
                                      chapterShow.removeWhere((element) => element.chapterKeyId == chapter.chapterKeyId);

                                      var bookId2Missing = refreshMissingChapterIndex(missingChapterIndex, chapterShow);
                                      var warning = bookId2Missing[chapter.bookId] ?? false;
                                      if (warning == false) {
                                        await Db().db.bookDao.updateBookWarningForChapter(chapter.bookId, warning, DateTime.now().millisecondsSinceEpoch);
                                        if (removeWarning != null) {
                                          await removeWarning!();
                                        }
                                      }
                                      parentLogic.update([ViewLogicChapterList.bodyId]);
                                      Get.back();
                                    });
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.delete_forever,
                              ),
                            ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                onTap: () {
                                  MsgBox.yesOrNo(
                                    title: I18nKey.labelWarning.tr,
                                    desc: I18nKey.labelDeleteVerse.tr,
                                    yes: () => delete(chapter: chapter),
                                  );
                                },
                                child: Text(I18nKey.btnDelete.tr),
                              ),
                              PopupMenuItem<String>(
                                onTap: () {
                                  MsgBox.myDialog(
                                      title: I18nKey.labelTips.tr,
                                      content: MsgBox.content(I18nKey.labelCopyToWhere.tr),
                                      action: MsgBox.buttonsWithDivider(buttons: [
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
                                      ]));
                                },
                                child: Text(I18nKey.btnCopy.tr),
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
              missingPanel,
              searchDetailPanel,
              SizedBox(
                height: getBodyViewHeight(),
                width: width,
                child: body,
              ),
            ],
          );
        });
  }

  Map<int, bool> refreshMissingChapterIndex(
    List<int> missingChapterIndex,
    List<ChapterShow> chapterShow,
  ) {
    missingChapterIndex.clear();

    Map<int, bool> bookId2Missing = {};
    for (int i = 0; i < chapterShow.length; i++) {
      var v = chapterShow[i];
      if (v.missing) {
        bookId2Missing[v.bookId] = true;
        missingChapterIndex.add(i);
      }
    }
    return bookId2Missing;
  }

  void updateOptions() {
    options = [];
    final Map<String, List<dynamic>> chaptersByBook = {};
    for (var chapter in originalChapterShow) {
      chaptersByBook.putIfAbsent(chapter.bookName, () => []).add(chapter);
    }

    final Set<String> uniqueBookNames = {};
    for (var book in originalBookShow) {
      uniqueBookNames.add(book.name);
    }

    final List<OptionBody> bookOptions = [];

    for (var bookName in uniqueBookNames) {
      final chapters = chaptersByBook[bookName] ?? [];

      final Set<int> chapterIndices = {};
      for (var chapter in chapters) {
        chapterIndices.add(chapter.chapterIndex);
      }

      final sortedIndices = chapterIndices.toList()..sort();
      sortedIndices.insert(0, -1);

      final chapterOptions = sortedIndices.map((k) {
        return OptionBody(
          label: (k == -1) ? I18nKey.labelAll.tr : '${k + 1}',
          value: k,
          next: [],
        );
      }).toList();

      bookOptions.add(OptionBody(
        label: bookName,
        value: 0,
        next: chapterOptions,
      ));
    }

    options.add(OptionBody(
      label: I18nKey.labelAll.tr,
      value: -1,
      next: [
        OptionBody(
          label: I18nKey.labelAll.tr,
          value: -1,
          next: [],
        )
      ],
    ));

    options.addAll(bookOptions);
  }

  void collectData() {
    updateOptions();
    missingChapterIndex = [];
    for (int i = 0; i < originalChapterShow.length; i++) {
      var v = originalChapterShow[i];
      if (v.missing) {
        missingChapterIndex.add(i);
      }
    }
  }

  void sort(List<ChapterShow> chapterShow, I18nKey key) {
    switch (key) {
      case I18nKey.labelSortPositionAsc:
        chapterShow.sort((a, b) => a.toSort().compareTo(b.toSort()));
        break;
      case I18nKey.labelSortPositionDesc:
        chapterShow.sort((a, b) => b.toSort().compareTo(a.toSort()));
        break;
      default:
        break;
    }
  }

  double getBodyViewHeight() {
    double ret = baseBodyViewHeight;
    if (missingChapterIndex.isNotEmpty) {
      ret = ret - missPanelHeight;
    }
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
