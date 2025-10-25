import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse_content_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/logic/view_logic.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
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
  final void Function(VerseShow verseShow) onNext;
  List<I18nKey> sortOptionKeys = [
    I18nKey.labelSortPositionAsc,
    I18nKey.labelSortPositionDesc,
    I18nKey.labelSortProgressAsc,
    I18nKey.labelSortProgressDesc,
    I18nKey.labelSortNextLearnDateAsc,
    I18nKey.labelSortNextLearnDateDesc,
  ];
  RxString search = RxString("");
  RxInt selectedSortIndex = 0.obs;

  List<OptionBody> options = [];

  RxInt chapterSelect = 0.obs;
  RxInt progressSelect = 0.obs;
  RxInt nextMonthSelect = 0.obs;
  bool showSearchDetailPanel = false;
  double searchDetailPanelHeight = 3 * (RowWidget.rowHeight + RowWidget.dividerHeight);

  String searchKey = '';

  RxInt bookSelect = 0.obs;

  List<String> sortOptions = [];
  List<String> progressOptions = [];
  List<String> nextMonthOptions = [];
  int missingVerseOffset = -1;
  List<int> progress = [];
  List<int> nextMonth = [];
  List<VerseShow> verseShow = [];
  late HistoryList historyList = HistoryList<T>(parentLogic);
  final T parentLogic;
  VoidCallback onChapterModified;
  List<BookShow> originalBookShow;
  List<ChapterShow> originalChapterShow;
  List<VerseShow> originalVerseShow;

  double baseBodyViewHeight = 0;
  int? selectVerseKeyId;

  ViewLogicVerseList({
    required this.parentLogic,
    required this.originalBookShow,
    required this.originalChapterShow,
    required this.originalVerseShow,
    required this.onChapterModified,
    required this.selectVerseKeyId,
    required this.onNext,
    required super.onSearchUnfocus,
    String? initContentNameSelect,
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
    verseShow = List.from(originalVerseShow);

    sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(verseShow, sortOptionKeys[selectedSortIndex.value]);

    collectData();

    if (initContentNameSelect != null) {
      bookSelect.value = options.indexWhere((opt) => opt.label == initContentNameSelect);
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
    return '${bookSelect.value},${chapterSelect.value},${progressSelect.value},${nextMonthSelect.value},${search.value}';
  }

  void scrollTo(int selectVerseKeyId) {
    int? selectedIndex;
    VerseShow? ss = VerseHelp.getCache(selectVerseKeyId);
    if (ss != null) {
      selectedIndex = verseShow.indexOf(ss);
    }
    if (selectedIndex != null) {
      itemScrollController.scrollTo(
        index: selectedIndex,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void trySearch({force = false}) {
    originalVerseShow = VerseHelp.cache;
    String newSearchKey = genSearchKey();
    if (!force && newSearchKey == searchKey) {
      return;
    }
    searchKey = newSearchKey;
    if (search.value.isNotEmpty || bookSelect.value != 0 || chapterSelect.value != 0 || progressSelect.value != 0 || nextMonthSelect.value != 0) {
      verseShow = originalVerseShow.where((e) {
        bool ret = true;
        if (ret && search.value.isNotEmpty) {
          ret = e.verseContent.contains(search.value);
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
            bookSelect.value = 0;
            ret = false;
          }
        }
        if (ret && progressSelect.value != 0) {
          ret = e.progress == progress[progressSelect.value];
        }
        if (ret && nextMonthSelect.value != 0) {
          int min = nextMonth[nextMonthSelect.value] * 100;
          int max = min + 99;
          ret = min < e.learnDate.value && e.learnDate.value < max;
        }
        return ret;
      }).toList();
    } else {
      verseShow = List.from(originalVerseShow);
    }
    sort(verseShow, sortOptionKeys[selectedSortIndex.value]);

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
        var book = await Db().db.bookDao.getBookByName(classroomId, options[bookSelect.value].label);
        if (book == null) {
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

  Future<void> copy({required VerseShow verse, required bool below}) async {
    await showOverlay(() async {
      int verseIndex = verse.verseIndex;
      if (below) {
        verseIndex++;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focus) {
        searchFocusNode.requestFocus();
      }
      trySearch();
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
                  I18nKey.labelProgress.tr,
                  progressOptions,
                  progressSelect,
                  changed: (index) {
                    progressSelect.value = index;
                    trySearch();
                  },
                ),
                RowWidget.buildDividerWithoutColor(),
                RowWidget.buildCupertinoPicker(
                  I18nKey.labelMonth.tr,
                  nextMonthOptions,
                  nextMonthSelect,
                  changed: (index) {
                    nextMonthSelect.value = index;
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
                    sort(verseShow, key);
                    parentLogic.update([ViewLogicVerseList.bodyId]);
                  },
                  pickWidth: 210.w,
                ),
                RowWidget.buildDividerWithoutColor(),
              ],
            ),
          );
        }
        Widget body = const SizedBox.shrink();
        var list = verseShow;

        if (list.isNotEmpty) {
          body = ScrollablePositionedList.builder(
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
            itemCount: list.length,
            itemBuilder: (context, index) {
              if (index >= list.length) {
                return const SizedBox.shrink();
              }
              final verse = list[index];
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
                              onNext(verse);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${verse.toChapterPos()}${verse.toVersePos()}',
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
                            onEdit: () {
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
                                        onPressed: () => copy(verse: verse, below: true),
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
        } else if (bookSelect.value > 0 && chapterSelect.value > 0 && search.value.isEmpty && progressSelect.value == 0 && nextMonthSelect.value == 0) {
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
        getContent: () {
          var c = VerseHelp.getCache(verse.verseId);
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

      bookOptions.add(
        OptionBody(
          label: bookName,
          value: 0,
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
    updateOptions();

    progress = [];
    nextMonth = [];
    for (int i = 0; i < verseShow.length; i++) {
      var v = verseShow[i];
      if (!progress.contains(v.progress)) {
        progress.add(v.progress);
      }
      int month = v.learnDate.value ~/ 100;
      if (!nextMonth.contains(month)) {
        nextMonth.add(month);
      }
    }
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

  static void sort(List<VerseShow> verseShow, I18nKey key) {
    switch (key) {
      case I18nKey.labelSortProgressAsc:
        verseShow.sort((a, b) {
          int progressComparison = a.progress.compareTo(b.progress);
          return progressComparison != 0 ? progressComparison : a.toSort().compareTo(b.toSort());
        });
        break;
      case I18nKey.labelSortProgressDesc:
        verseShow.sort((a, b) {
          int progressComparison = b.progress.compareTo(a.progress);
          return progressComparison != 0 ? progressComparison : a.toSort().compareTo(b.toSort());
        });
        break;
      case I18nKey.labelSortPositionAsc:
        verseShow.sort((a, b) => a.toSort().compareTo(b.toSort()));
        break;
      case I18nKey.labelSortPositionDesc:
        verseShow.sort((a, b) => b.toSort().compareTo(a.toSort()));
        break;
      case I18nKey.labelSortNextLearnDateAsc:
        verseShow.sort((a, b) {
          int nextComparison = a.learnDate.value.compareTo(b.learnDate.value);
          return nextComparison != 0 ? nextComparison : a.toSort().compareTo(b.toSort());
        });
        break;
      case I18nKey.labelSortNextLearnDateDesc:
        verseShow.sort((a, b) {
          int nextComparison = b.learnDate.value.compareTo(a.learnDate.value);
          return nextComparison != 0 ? nextComparison : a.toSort().compareTo(b.toSort());
        });
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
    searchController.dispose();
    searchFocusNode.dispose();
  }

  void setBookSelectByName(String bookName) {
    bookSelect.value = options.indexWhere((opt) => opt.label == bookName);
  }
}
