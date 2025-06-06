import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/lesson_key.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
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

class ViewLogicLessonList<T extends GetxController> extends ViewLogic {
  static const String bodyId = "LessonList.bodyId";
  late HistoryList historyList = HistoryList<T>(parentLogic);

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  double searchDetailPanelHeight = 3 * (RowWidget.rowHeight + RowWidget.dividerHeight);

  double missPanelHeight = RowWidget.rowHeight + RowWidget.dividerHeight;
  final RxString search = RxString("");
  final T parentLogic;
  List<BookShow> originalBookShow;
  List<LessonShow> originalLessonShow;
  List<LessonShow> lessonShow = [];
  VoidCallback onLessonModified;
  final Future<void> Function()? removeWarning;

  bool showSearchDetailPanel = false;
  RxInt bookSelect = 0.obs;
  RxInt chapterSelect = 0.obs;
  String searchKey = '';
  List<OptionBody> options = [];

  // for collect search data, and missing lesson
  int missingLessonOffset = -1;
  List<int> missingLessonIndex = [];
  List<String> sortOptions = [];
  RxInt selectedSortIndex = 0.obs;
  List<I18nKey> sortOptionKeys = [
    I18nKey.labelSortPositionAsc,
    I18nKey.labelSortPositionDesc,
  ];

  double baseBodyViewHeight = 0;

  ViewLogicLessonList({
    required VoidCallback onSearchUnfocus,
    required this.onLessonModified,
    required this.originalBookShow,
    required this.originalLessonShow,
    required this.parentLogic,
    required this.removeWarning,
    String? initContentNameSelect,
    int? initLessonSelect,
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
    lessonShow = List.from(originalLessonShow);

    // for sorting and content
    sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(lessonShow, sortOptionKeys[selectedSortIndex.value]);

    collectData();

    if (initContentNameSelect != null) {
      bookSelect.value = options.indexWhere((opt) => opt.label == initContentNameSelect);
      if (bookSelect.value < options.length) {
        final selectedBook = options[bookSelect.value];
        if (initLessonSelect != null) {
          if (initLessonSelect + 1 < selectedBook.next.length) {
            chapterSelect.value = initLessonSelect + 1;
          }
        }
      }
    }
  }

  void tryUpdateDetailSearchPanel(bool newShow) {
    if (showSearchDetailPanel != newShow) {
      showSearchDetailPanel = newShow;
      parentLogic.update([ViewLogicLessonList.bodyId]);
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
      lessonShow = originalLessonShow.where((e) {
        bool ret = true;
        if (ret && search.value.isNotEmpty) {
          ret = e.lessonContent.contains(search.value);
        }
        if (ret && bookSelect.value != 0) {
          if (bookSelect.value < options.length) {
            final selectedBook = options[bookSelect.value];
            ret = e.contentName == selectedBook.label;
            if (ret && chapterSelect.value != 0) {
              if (chapterSelect.value < selectedBook.next.length) {
                final selectedLesson = selectedBook.next[chapterSelect.value];
                ret = e.lessonIndex == selectedLesson.value;
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
      lessonShow = List.from(originalLessonShow);
    }
    sort(lessonShow, sortOptionKeys[selectedSortIndex.value]);
    refreshMissingLessonIndex(missingLessonIndex, lessonShow);

    parentLogic.update([ViewLogicLessonList.bodyId]);
  }

  Future<void> refresh(LessonKey? lessonKey) async {
    if (lessonKey != null) {
      await VerseHelp.getVerses(
        force: true,
        query: QueryLesson(
          contentSerial: lessonKey.contentSerial,
          minLessonIndex: lessonKey.lessonIndex,
        ),
      );
    }
    originalLessonShow = await LessonHelp.getLessons(force: true);
    onLessonModified();
    collectData();
    trySearch(force: true);
    await Get.find<GsCrLogic>().init();
  }

  delete({required LessonShow lesson}) async {
    bool success = await showOverlay<bool>(() async {
      Map<String, dynamic> out = {};
      bool ok = await Db().db.lessonKeyDao.deleteNormalLesson(lesson.lessonKeyId, out);
      if (!ok) {
        return false;
      }
      LessonKey lessonKey = out['lessonKey'] as LessonKey;
      await refresh(lessonKey);
      return true;
    }, I18nKey.labelDeleting.tr);
    if (success) {
      Snackbar.show(I18nKey.labelDeleted.tr);
    }
    Get.back();
  }

  addFirst() async {
    bool success = false;
    if (bookSelect.value > 0) {
      success = await showOverlay<bool>(() async {
        var classroomId = Classroom.curr;
        var content = await Db().db.contentDao.getContentByName(classroomId, options[bookSelect.value].label);
        if (content == null) {
          Snackbar.show(I18nKey.labelNoContent.tr);
          return false;
        }
        var chapterCount = await Db().db.lessonDao.count(classroomId, content.serial) ?? 0;
        if (chapterCount == 0) {
          await Db().db.lessonKeyDao.addFirstLesson(content.serial);
          await refresh(null);
        }
        return true;
      }, I18nKey.labelCopying.tr);
    }
    if (success) {
      Snackbar.show(I18nKey.labelAddSuccess.tr);
    }
  }

  copy({required LessonShow lesson, required bool below}) async {
    bool success = await showOverlay<bool>(() async {
      int lessonIndex = lesson.lessonIndex;
      if (below) {
        lessonIndex++;
      }
      Map<String, dynamic> out = {};
      var ok = await Db().db.lessonKeyDao.addLesson(lesson, lessonIndex, out);
      if (!ok) {
        return false;
      }
      LessonKey lessonKey = out['lessonKey'] as LessonKey;
      await refresh(lessonKey);
      return true;
    }, I18nKey.labelCopying.tr);
    if (success) {
      Snackbar.show(I18nKey.labelCopied.tr);
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
        id: ViewLogicLessonList.bodyId,
        builder: (_) {
          var list = lessonShow;

          Widget missingPanel = const SizedBox.shrink();
          if (missingLessonIndex.isNotEmpty) {
            missingPanel = SizedBox(
              height: missPanelHeight,
              width: width,
              child: Column(
                children: [
                  RowWidget.buildWidgetsWithTitle(I18nKey.labelFindUnnecessaryLessons.tr, [
                    IconButton(
                        onPressed: () {
                          if (missingLessonOffset - 1 < 0) {
                            missingLessonOffset = 0;
                          } else {
                            missingLessonOffset--;
                          }
                          itemScrollController.scrollTo(
                            index: missingLessonIndex[missingLessonOffset],
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back)),
                    IconButton(
                        onPressed: () {
                          if (missingLessonOffset + 1 >= missingLessonIndex.length) {
                            missingLessonOffset = missingLessonIndex.length - 1;
                          } else {
                            missingLessonOffset++;
                          }
                          itemScrollController.scrollTo(
                            index: missingLessonIndex[missingLessonOffset],
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
                      OptionHead(title: I18nKey.labelBook.tr, value: bookSelect),
                      OptionHead(title: I18nKey.labelLesson.tr, value: chapterSelect),
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
                      sort(lessonShow, key);
                      parentLogic.update([ViewLogicLessonList.bodyId]);
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
                final lesson = list[index];
                return Card(
                  color: lesson.missing ? Colors.red : null,
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
                                lesson.toPos(),
                                style: const TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                            SizedBox(height: 8, width: width),
                            ExpandableText(
                              title: I18nKey.labelLessonName.tr,
                              text: ': ${lesson.lessonContent}',
                              version: lesson.lessonContentVersion,
                              limit: 60,
                              style: const TextStyle(fontSize: 14),
                              selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                              versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                              selectText: search.value,
                              onEdit: () {
                                searchFocusNode.unfocus();
                                var contentM = jsonDecode(lesson.lessonContent);
                                var content = const JsonEncoder.withIndent(' ').convert(contentM);
                                Editor.show(
                                  Get.context!,
                                  I18nKey.labelLessonName.tr,
                                  content,
                                  (str) async {
                                    await Db().db.lessonKeyDao.updateLessonContent(lesson.lessonKeyId, str);
                                    parentLogic.update([ViewLogicLessonList.bodyId]);
                                  },
                                  qrPagePath: Nav.gsCrContentScan.path,
                                  onHistory: () {
                                    historyList.show(TextVersionType.lessonContent, lesson.lessonKeyId);
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
                          if (lesson.missing)
                            IconButton(
                              onPressed: () {
                                MsgBox.yesOrNo(
                                  title: I18nKey.labelDelete.tr,
                                  desc: I18nKey.labelDeleteLesson.tr,
                                  yes: () {
                                    showTransparentOverlay(() async {
                                      var ok = await Db().db.lessonKeyDao.deleteAbnormalLesson(lesson.lessonKeyId);
                                      if (ok == false) {
                                        return;
                                      }
                                      LessonHelp.deleteCache(lesson.lessonKeyId);
                                      lessonShow.removeWhere((element) => element.lessonKeyId == lesson.lessonKeyId);

                                      var contentId2Missing = refreshMissingLessonIndex(missingLessonIndex, lessonShow);
                                      var warning = contentId2Missing[lesson.contentId] ?? false;
                                      if (warning == false) {
                                        await Db().db.contentDao.updateContentWarningForLesson(lesson.contentId, warning, DateTime.now().millisecondsSinceEpoch);
                                        if (removeWarning != null) {
                                          await removeWarning!();
                                        }
                                      }
                                      parentLogic.update([ViewLogicLessonList.bodyId]);
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
                                    yes: () => delete(lesson: lesson),
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
                                          onPressed: () => copy(lesson: lesson, below: false),
                                        ),
                                        MsgBox.button(
                                          text: I18nKey.btnBelow.tr,
                                          onPressed: () => copy(lesson: lesson, below: true),
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
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: I18nKey.labelTipForAddingContent.trArgs([options[bookSelect.value].label]),
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

  Map<int, bool> refreshMissingLessonIndex(
    List<int> missingLessonIndex,
    List<LessonShow> lessonShow,
  ) {
    missingLessonIndex.clear();

    Map<int, bool> contentId2Missing = {};
    for (int i = 0; i < lessonShow.length; i++) {
      var v = lessonShow[i];
      if (v.missing) {
        contentId2Missing[v.contentId] = true;
        missingLessonIndex.add(i);
      }
    }
    return contentId2Missing;
  }

  void updateOptions() {
    options = [];
    final Map<String, List<dynamic>> lessonsByBook = {};
    for (var lesson in originalLessonShow) {
      lessonsByBook.putIfAbsent(lesson.contentName, () => []).add(lesson);
    }

    final Set<String> uniqueBookNames = {};
    for (var book in originalBookShow) {
      uniqueBookNames.add(book.name);
    }

    final List<OptionBody> bookOptions = [];

    for (var bookName in uniqueBookNames) {
      final lessons = lessonsByBook[bookName] ?? [];

      final Set<int> lessonIndices = {};
      for (var lesson in lessons) {
        lessonIndices.add(lesson.lessonIndex);
      }

      final sortedIndices = lessonIndices.toList()..sort();
      sortedIndices.insert(0, -1);

      final lessonOptions = sortedIndices.map((k) {
        return OptionBody(
          label: (k == -1) ? I18nKey.labelAll.tr : '${k + 1}',
          value: k,
          next: [],
        );
      }).toList();

      bookOptions.add(OptionBody(
        label: bookName,
        value: 0,
        next: lessonOptions,
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
    missingLessonIndex = [];
    for (int i = 0; i < originalLessonShow.length; i++) {
      var v = originalLessonShow[i];
      if (v.missing) {
        missingLessonIndex.add(i);
      }
    }
  }

  sort(List<LessonShow> lessonShow, I18nKey key) {
    switch (key) {
      case I18nKey.labelSortPositionAsc:
        lessonShow.sort((a, b) => a.toSort().compareTo(b.toSort()));
        break;
      case I18nKey.labelSortPositionDesc:
        lessonShow.sort((a, b) => b.toSort().compareTo(a.toSort()));
        break;
      default:
        break;
    }
  }

  double getBodyViewHeight() {
    double ret = baseBodyViewHeight;
    if (missingLessonIndex.isNotEmpty) {
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
