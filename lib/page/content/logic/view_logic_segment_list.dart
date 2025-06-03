import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/logic/widget/lesson_list.dart';
import 'package:repeat_flutter/logic/widget/editor.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/logic/view_logic.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ViewLogicSegmentList<T extends GetxController> extends ViewLogic {
  static const String bodyId = "SegmentList.bodyId";
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
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

  RxInt chapterSelect = 0.obs;
  RxInt progressSelect = 0.obs;
  RxInt nextMonthSelect = 0.obs;
  bool showSearchDetailPanel = false;
  double searchDetailPanelHeight = 3 * (RowWidget.rowHeight + RowWidget.dividerHeight);

  double missPanelHeight = RowWidget.rowHeight + RowWidget.dividerHeight;
  String searchKey = '';
  List<int> missingSegmentIndex = [];

  List<String> bookOptions = [];
  RxInt bookSelect = 0.obs;

  List<String> sortOptions = [];
  List<String> lessonOptions = [];
  List<String> progressOptions = [];
  List<String> nextMonthOptions = [];
  int missingSegmentOffset = -1;
  List<int> lessonIndex = [];
  List<int> progress = [];
  List<int> nextMonth = [];
  List<SegmentShow> segmentShow = [];
  late HistoryList historyList = HistoryList<T>(parentLogic);
  late LessonList lessonList = LessonList<T>(parentLogic);
  final T parentLogic;
  Future<void> Function()? removeWarning;
  VoidCallback onLessonModified;
  List<BookShow> originalBookShow;
  List<LessonShow> originalLessonShow;
  List<SegmentShow> originalSegmentShow;

  double baseBodyViewHeight = 0;
  int? selectSegmentKeyId;

  ViewLogicSegmentList({
    required VoidCallback onSearchUnfocus,
    required this.parentLogic,
    required this.originalBookShow,
    required this.originalLessonShow,
    required this.originalSegmentShow,
    required this.removeWarning,
    required this.onLessonModified,
    required this.selectSegmentKeyId,
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
    segmentShow = List.from(originalSegmentShow);

    sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(segmentShow, sortOptionKeys[selectedSortIndex.value]);

    collectData();

    if (initContentNameSelect != null) {
      bookSelect.value = bookOptions.indexOf(initContentNameSelect);
    }
    if (initLessonSelect != null) {
      chapterSelect.value = lessonOptions.indexOf('${initLessonSelect + 1}');
    }
  }

  String genSearchKey() {
    return '${bookSelect.value},${chapterSelect.value},${progressSelect.value},${nextMonthSelect.value},${search.value}';
  }

  void scrollTo(int selectSegmentKeyId) {
    int? selectedIndex;
    SegmentShow? ss = SegmentHelp.getCache(selectSegmentKeyId);
    if (ss != null) {
      selectedIndex = segmentShow.indexOf(ss);
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
    String newSearchKey = genSearchKey();
    if (!force && newSearchKey == searchKey) {
      return;
    }
    searchKey = newSearchKey;
    if (search.value.isNotEmpty || bookSelect.value != 0 || chapterSelect.value != 0 || progressSelect.value != 0 || nextMonthSelect.value != 0) {
      segmentShow = originalSegmentShow.where((e) {
        bool ret = true;
        if (ret && search.value.isNotEmpty) {
          ret = e.segmentContent.contains(search.value);
          if (ret == false) {
            ret = e.segmentNote.contains(search.value);
          }
        }
        if (ret && bookSelect.value != 0) {
          if (bookSelect.value < 0 || bookSelect.value >= bookOptions.length) {
            return false;
          }
          ret = e.contentName == bookOptions[bookSelect.value];
        }
        if (ret && chapterSelect.value != 0) {
          ret = e.lessonIndex == lessonIndex[chapterSelect.value];
        }
        if (ret && progressSelect.value != 0) {
          ret = e.progress == progress[progressSelect.value];
        }
        if (ret && nextMonthSelect.value != 0) {
          int min = nextMonth[nextMonthSelect.value] * 100;
          int max = min + 99;
          ret = min < e.next.value && e.next.value < max;
        }
        return ret;
      }).toList();
    } else {
      segmentShow = List.from(originalSegmentShow);
    }
    sort(segmentShow, sortOptionKeys[selectedSortIndex.value]);
    refreshMissingSegmentIndex(missingSegmentIndex, segmentShow);

    parentLogic.update([ViewLogicSegmentList.bodyId]);
  }

  delete({required SegmentShow segment}) async {
    await showOverlay(() async {
      bool ok = await Db().db.scheduleDao.deleteNormalSegment(segment.segmentKeyId);
      if (!ok) {
        return false;
      }
      originalSegmentShow = await SegmentHelp.getSegments(
        force: true,
        query: QueryLesson(
          contentSerial: segment.contentSerial,
          chapterIndex: segment.lessonIndex,
        ),
      );
      trySearch(force: true);
      await Get.find<GsCrLogic>().init();
    }, I18nKey.labelDeleting.tr);
    Snackbar.show(I18nKey.labelDeleted.tr);
    Get.back();
  }

  addFirst() async {
    if (bookSelect.value > 0 && chapterSelect.value > 0) {
      await showOverlay(() async {
        var classroomId = Classroom.curr;
        var content = await Db().db.contentDao.getContentByName(classroomId, bookOptions[bookSelect.value]);
        if (content == null) {
          Snackbar.show(I18nKey.labelNoContent.tr);
          return;
        }
        int chapterIndex = chapterSelect.value - 1;
        var chapterCount = await Db().db.lessonDao.count(classroomId, content.serial) ?? 0;
        if (chapterCount == 0) {
          await Db().db.lessonKeyDao.addFirstLesson(content.serial);
          await LessonHelp.getLessons(force: true);
          onLessonModified();
          chapterIndex = 0;
        }

        await Db().db.scheduleDao.addFirstSegment(content.serial, chapterIndex);
        originalSegmentShow = await SegmentHelp.getSegments(
          force: true,
          query: QueryLesson(
            contentSerial: content.serial,
            chapterIndex: chapterIndex,
          ),
        );
        trySearch(force: true);
      }, I18nKey.labelAdding.tr);
      Snackbar.show(I18nKey.labelAddSuccess.tr);
    }
  }

  copy({required SegmentShow segment, required bool below}) async {
    await showOverlay(() async {
      int segmentIndex = segment.segmentIndex;
      if (below) {
        segmentIndex++;
      }
      var segmentKeyId = await Db().db.scheduleDao.addSegment(segment, segmentIndex);
      if (segmentKeyId == 0) {
        return;
      }
      originalSegmentShow = await SegmentHelp.getSegments(
        force: true,
        query: QueryLesson(
          contentSerial: segment.contentSerial,
          chapterIndex: segment.lessonIndex,
        ),
      );
      trySearch(force: true);
    }, I18nKey.labelCopying.tr);
    Snackbar.show(I18nKey.labelCopied.tr);
    Get.back();
  }

  void tryUpdateDetailSearchPanel(bool newShow) {
    if (showSearchDetailPanel != newShow) {
      showSearchDetailPanel = newShow;
      parentLogic.update([ViewLogicSegmentList.bodyId]);
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
      if (selectSegmentKeyId != null) {
        scrollTo(selectSegmentKeyId!);
      }
    });
    return GetBuilder<T>(
        id: ViewLogicSegmentList.bodyId,
        builder: (_) {
          Widget missingPanel = const SizedBox.shrink();
          if (missingSegmentIndex.isNotEmpty) {
            missingPanel = SizedBox(
              height: missPanelHeight,
              width: width,
              child: Column(
                children: [
                  RowWidget.buildWidgetsWithTitle(I18nKey.labelFindUnnecessarySegments.tr, [
                    IconButton(
                        onPressed: () {
                          if (missingSegmentOffset - 1 < 0) {
                            missingSegmentOffset = 0;
                          } else {
                            missingSegmentOffset--;
                          }
                          itemScrollController.scrollTo(
                            index: missingSegmentIndex[missingSegmentOffset],
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back)),
                    IconButton(
                        onPressed: () {
                          if (missingSegmentOffset + 1 >= missingSegmentIndex.length) {
                            missingSegmentOffset = missingSegmentIndex.length - 1;
                          } else {
                            missingSegmentOffset++;
                          }
                          itemScrollController.scrollTo(
                            index: missingSegmentIndex[missingSegmentOffset],
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
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  RowWidget.buildCupertinoPicker(
                    I18nKey.labelContent.tr,
                    bookOptions,
                    bookSelect,
                    changed: (index) {
                      bookSelect.value = index;
                      trySearch();
                    },
                  ),
                  RowWidget.buildDividerWithoutColor(),
                  RowWidget.buildCupertinoPicker(
                    I18nKey.labelLessonName.tr,
                    lessonOptions,
                    chapterSelect,
                    changed: (index) {
                      chapterSelect.value = index;
                      trySearch();
                    },
                  ),
                  RowWidget.buildDividerWithoutColor(),
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
                      sort(segmentShow, key);
                      parentLogic.update([ViewLogicSegmentList.bodyId]);
                    },
                    pickWidth: 210.w,
                  ),
                  RowWidget.buildDividerWithoutColor(),
                ],
              ),
            );
          }
          Widget body = const SizedBox.shrink();
          var list = segmentShow;

          if (list.isNotEmpty) {
            body = ScrollablePositionedList.builder(
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
              itemCount: list.length,
              itemBuilder: (context, index) {
                if (index >= list.length) {
                  return const SizedBox.shrink();
                }
                final segment = list[index];
                return Card(
                  color: segment.missing ? Colors.red : null,
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
                                '${segment.toLessonPos()}${segment.toSegmentPos()}',
                                style: const TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                            SizedBox(height: 8, width: width),
                            ExpandableText(
                              title: I18nKey.labelKey.tr,
                              text: ': ${segment.k}',
                              limit: 50,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                              selectText: search.value,
                            ),
                            const SizedBox(height: 8),
                            ExpandableText(
                              title: I18nKey.labelSegmentName.tr,
                              text: ': ${segment.segmentContent}',
                              version: segment.segmentContentVersion,
                              limit: 60,
                              style: const TextStyle(fontSize: 14),
                              selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                              versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                              selectText: search.value,
                              onEdit: () {
                                searchFocusNode.unfocus();
                                var contentM = jsonDecode(segment.segmentContent);
                                var content = const JsonEncoder.withIndent(' ').convert(contentM);
                                Editor.show(
                                  Get.context!,
                                  I18nKey.labelSegmentName.tr,
                                  content,
                                  (str) async {
                                    await Db().db.scheduleDao.tUpdateSegmentContent(segment.segmentKeyId, str);
                                    parentLogic.update([ViewLogicSegmentList.bodyId]);
                                  },
                                  qrPagePath: Nav.gsCrContentScan.path,
                                  onHistory: () {
                                    historyList.show(TextVersionType.segmentContent, segment.segmentKeyId);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            ExpandableText(
                              title: I18nKey.labelNote.tr,
                              text: ': ${segment.segmentNote}',
                              limit: 60,
                              version: segment.segmentNoteVersion,
                              style: const TextStyle(fontSize: 14),
                              selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                              versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                              selectText: search.value,
                              onEdit: () {
                                searchFocusNode.unfocus();
                                Editor.show(
                                  Get.context!,
                                  I18nKey.labelNote.tr,
                                  segment.segmentNote,
                                  (str) async {
                                    await Db().db.scheduleDao.tUpdateSegmentNote(segment.segmentKeyId, str);
                                    parentLogic.update([ViewLogicSegmentList.bodyId]);
                                  },
                                  qrPagePath: Nav.gsCrContentScan.path,
                                  onHistory: () {
                                    historyList.show(TextVersionType.segmentNote, segment.segmentKeyId);
                                  },
                                );
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
                                      editProgressWithMsgBox(segment);
                                    },
                                    child: Text(
                                      '${I18nKey.labelProgress.tr}: ${segment.progress}',
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
                                      editProgressWithMsgBox(segment);
                                    },
                                    child: Text(
                                      '${I18nKey.labelSetNextLearnDate.tr}: ${segment.next.format()}',
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
                          if (segment.missing)
                            IconButton(
                              onPressed: () {
                                MsgBox.yesOrNo(
                                  title: I18nKey.labelDelete.tr,
                                  desc: I18nKey.labelDeleteSegment.tr,
                                  yes: () {
                                    showTransparentOverlay(() async {
                                      await Db().db.scheduleDao.deleteAbnormalSegment(segment.segmentKeyId);

                                      SegmentHelp.deleteCache(segment.segmentKeyId);
                                      segmentShow.removeWhere((element) => element.segmentKeyId == segment.segmentKeyId);

                                      var contentId2Missing = refreshMissingSegmentIndex(missingSegmentIndex, segmentShow);
                                      var warning = contentId2Missing[segment.contentId] ?? false;
                                      if (warning == false) {
                                        await Db().db.contentDao.updateContentWarningForSegment(segment.contentId, warning, DateTime.now().millisecondsSinceEpoch);
                                        if (removeWarning != null) {
                                          await removeWarning!();
                                        }
                                      }
                                      parentLogic.update([ViewLogicSegmentList.bodyId]);
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
                                    desc: I18nKey.labelDeleteSegment.tr,
                                    yes: () => delete(segment: segment),
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
                                          onPressed: () => copy(segment: segment, below: false),
                                        ),
                                        MsgBox.button(
                                          text: I18nKey.btnBelow.tr,
                                          onPressed: () => copy(segment: segment, below: true),
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
          } else if (bookSelect.value > 0 && chapterSelect.value > 0) {
            body = Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: I18nKey.labelTipForAddingContent.trArgs(["${bookOptions[bookSelect.value]}-${chapterSelect.value}"]),
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
              searchDetailPanel,
              missingPanel,
              SizedBox(
                height: getBodyViewHeight(),
                width: width,
                child: body,
              ),
            ],
          );
        });
  }

  static Map<int, bool> refreshMissingSegmentIndex(
    List<int> missingSegmentIndex,
    List<SegmentShow> segmentShow,
  ) {
    missingSegmentIndex.clear();

    Map<int, bool> contentId2Missing = {};
    for (int i = 0; i < segmentShow.length; i++) {
      var v = segmentShow[i];
      if (v.missing) {
        contentId2Missing[v.contentId] = true;
        missingSegmentIndex.add(i);
      }
    }
    return contentId2Missing;
  }

  void collectData() {
    bookOptions = [];
    for (int i = 0; i < originalBookShow.length; i++) {
      var v = originalBookShow[i];
      if (!bookOptions.contains(v.name)) {
        bookOptions.add(v.name);
      }
    }
    bookOptions.insert(0, I18nKey.labelAll.tr);

    lessonIndex = [];
    for (int i = 0; i < originalLessonShow.length; i++) {
      var v = originalLessonShow[i];
      if (!lessonIndex.contains(v.lessonIndex)) {
        lessonIndex.add(v.lessonIndex);
      }
    }

    lessonIndex.sort();
    lessonIndex.insert(0, -1);
    lessonOptions = lessonIndex.map((k) {
      if (k == -1) {
        return I18nKey.labelAll.tr;
      }
      return '${k + 1}';
    }).toList();

    missingSegmentIndex = [];
    progress = [];
    nextMonth = [];
    for (int i = 0; i < segmentShow.length; i++) {
      var v = segmentShow[i];
      if (v.missing) {
        missingSegmentIndex.add(i);
      }
      if (!progress.contains(v.progress)) {
        progress.add(v.progress);
      }
      int month = v.next.value ~/ 100;
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

  static sort(List<SegmentShow> segmentShow, I18nKey key) {
    switch (key) {
      case I18nKey.labelSortProgressAsc:
        segmentShow.sort((a, b) {
          int progressComparison = a.progress.compareTo(b.progress);
          return progressComparison != 0 ? progressComparison : a.toSort().compareTo(b.toSort());
        });
        break;
      case I18nKey.labelSortProgressDesc:
        segmentShow.sort((a, b) {
          int progressComparison = b.progress.compareTo(a.progress);
          return progressComparison != 0 ? progressComparison : a.toSort().compareTo(b.toSort());
        });
        break;
      case I18nKey.labelSortPositionAsc:
        segmentShow.sort((a, b) => a.toSort().compareTo(b.toSort()));
        break;
      case I18nKey.labelSortPositionDesc:
        segmentShow.sort((a, b) => b.toSort().compareTo(a.toSort()));
        break;
      case I18nKey.labelSortNextLearnDateAsc:
        segmentShow.sort((a, b) {
          int nextComparison = a.next.value.compareTo(b.next.value);
          return nextComparison != 0 ? nextComparison : a.toSort().compareTo(b.toSort());
        });
        break;
      case I18nKey.labelSortNextLearnDateDesc:
        segmentShow.sort((a, b) {
          int nextComparison = b.next.value.compareTo(a.next.value);
          return nextComparison != 0 ? nextComparison : a.toSort().compareTo(b.toSort());
        });
        break;
      default:
        break;
    }
  }

  double getBodyViewHeight() {
    double ret = baseBodyViewHeight;
    if (missingSegmentIndex.isNotEmpty) {
      ret = ret - missPanelHeight;
    }
    if (showSearchDetailPanel) {
      ret = ret - searchDetailPanelHeight;
    }
    return ret;
  }

  Future<void> editProgressWithMsgBox(SegmentShow segment) async {
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
          await editProgress(segment);
        },
      );
    } else {
      await editProgress(segment);
    }
  }

  Future<void> editProgress(SegmentShow segment) async {
    EditProgress.show(segment.segmentKeyId, warning: I18nKey.labelSettingLearningProgressWarning.tr, title: I18nKey.btnOk.tr, callback: (p, n) async {
      await Db().db.scheduleDao.jumpDirectly(segment.segmentKeyId, p, n);
      Get.back();
      parentLogic.update([ViewLogicSegmentList.bodyId]);
    });
  }

  @override
  dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
  }
}
