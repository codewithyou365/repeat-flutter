import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SegmentShowLogic<T extends GetxController> {
  static const String bodyId = "SegmentShowLogic.bodyId";
  static const String findUnnecessarySegmentsId = "SegmentShowLogic.findUnnecessarySegmentsId";
  static const String detailSearchId = "SegmentShowLogic.searchId";

  final T parentLogic;

  SegmentShowLogic(this.parentLogic);

  void refreshMissingSegmentIndex(
    List<int> missingSegmentIndex,
    List<SegmentShow> segmentShow,
  ) {
    missingSegmentIndex.clear();
    for (int i = 0; i < segmentShow.length; i++) {
      var v = segmentShow[i];
      if (v.missing) {
        missingSegmentIndex.add(i);
      }
    }
  }

  void collectDataFromSegments(
    List<int> missingSegmentIndex,
    List<String> contentName,
    List<int> lesson,
    List<int> progress,
    List<int> nextMonth,
    List<SegmentShow> segmentShow,
  ) {
    for (int i = 0; i < segmentShow.length; i++) {
      var v = segmentShow[i];
      if (v.missing) {
        missingSegmentIndex.add(i);
      }
      if (!contentName.contains(v.contentName)) {
        contentName.add(v.contentName);
      }
      if (!lesson.contains(v.lessonIndex)) {
        lesson.add(v.lessonIndex);
      }
      if (!progress.contains(v.progress)) {
        progress.add(v.progress);
      }
      int month = v.next.value ~/ 100;
      if (!nextMonth.contains(month)) {
        nextMonth.add(month);
      }
    }
    lesson.sort();
    progress.sort();
    nextMonth.sort();
    contentName.insert(0, I18nKey.labelAll.tr);
    lesson.insert(0, -1);
    progress.insert(0, -1);
    nextMonth.insert(0, -1);
  }

  sort(List<SegmentShow> segmentShow, I18nKey key) {
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

  double getBodyViewHeight(List<int> missingSegmentIndex, double baseBodyViewHeight) {
    if (missingSegmentIndex.isNotEmpty) {
      return baseBodyViewHeight - RowWidget.rowHeight - RowWidget.dividerHeight;
    } else {
      return baseBodyViewHeight;
    }
  }

  show({bool all = false, String? initContentNameSelect, int? initLessonSelect}) async {
    showTransparentOverlay(() async {
      List<SegmentShow> segmentShow = [];
      if (all) {
        segmentShow = await Db().db.scheduleDao.getAllSegment(Classroom.curr);
      } else {
        segmentShow = await Db().db.scheduleDao.getSegment(Classroom.curr);
      }
      showSheet(
        segmentShow,
        initContentNameSelect: initContentNameSelect,
        initLessonSelect: initLessonSelect,
      );
    });
  }

  showSheet(List<SegmentShow> originalSegmentShow, {String? initContentNameSelect, int? initLessonSelect}) {
    // for search and controls
    RxString search = RxString("");
    bool showSearchDetailPanel = false;
    final TextEditingController searchController = TextEditingController(text: search.value);
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        showSearchDetailPanel = true;
      } else {
        showSearchDetailPanel = false;
      }
      parentLogic.update([SegmentShowLogic.detailSearchId]);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    // for sorting and content
    List<SegmentShow> segmentShow = List.from(originalSegmentShow);
    RxInt selectedSortIndex = 0.obs;
    List<I18nKey> sortOptionKeys = [
      I18nKey.labelSortPositionAsc,
      I18nKey.labelSortPositionDesc,
      I18nKey.labelSortProgressAsc,
      I18nKey.labelSortProgressDesc,
      I18nKey.labelSortNextLearnDateAsc,
      I18nKey.labelSortNextLearnDateDesc,
    ];
    List<String> sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(segmentShow, sortOptionKeys[selectedSortIndex.value]);

    // for collect search data, and missing segment
    int missingSegmentOffset = -1;
    List<int> missingSegmentIndex = [];
    List<String> contentNameOptions = [];
    List<int> lesson = [];
    List<int> progress = [];
    List<int> nextMonth = [];
    collectDataFromSegments(
      missingSegmentIndex,
      contentNameOptions,
      lesson,
      progress,
      nextMonth,
      segmentShow, // keep consistent with view below.
    );
    RxInt contentNameSelect = 0.obs;
    RxInt lessonSelect = 0.obs;
    RxInt progressSelect = 0.obs;
    RxInt nextMonthSelect = 0.obs;
    List<String> lessonOptions = lesson.map((k) {
      if (k == -1) {
        return I18nKey.labelAll.tr;
      }
      return '${k + 1}';
    }).toList();
    List<String> progressOptions = progress.map((k) {
      if (k == -1) {
        return I18nKey.labelAll.tr;
      }
      return k.toString();
    }).toList();
    List<String> nextMonthOptions = nextMonth.map((k) {
      if (k == -1) {
        return I18nKey.labelAll.tr;
      }
      return '${k.toString().substring(0, 4)}-${k.toString().substring(4, 6)}';
    }).toList();
    final ItemScrollController itemScrollController = ItemScrollController();
    final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

    // for height
    var mediaQueryData = MediaQuery.of(Get.context!);
    double bodyViewHeight = 0;
    final Size screenSize = mediaQueryData.size;
    final totalHeight = screenSize.height - mediaQueryData.padding.top;
    final baseBodyViewHeight = totalHeight - RowWidget.rowHeight - RowWidget.dividerHeight - Sheet.paddingVertical * 2;
    bodyViewHeight = getBodyViewHeight(missingSegmentIndex, baseBodyViewHeight);

    String genSearchKey() {
      return '${contentNameSelect.value},${lessonSelect.value},${progressSelect.value},${nextMonthSelect.value},${search.value}';
    }

    String searchKey = genSearchKey();
    void trySearch() {
      String newSearchKey = genSearchKey();
      if (newSearchKey == searchKey) {
        return;
      }
      searchKey = newSearchKey;
      if (search.value.isNotEmpty || contentNameSelect.value != 0 || lessonSelect.value != 0 || progressSelect.value != 0 || nextMonthSelect.value != 0) {
        segmentShow = originalSegmentShow.where((e) {
          bool ret = true;
          if (ret && search.value.isNotEmpty) {
            ret = e.segmentContent.contains(search.value);
          }
          if (ret && contentNameSelect.value != 0) {
            ret = e.contentName == contentNameOptions[contentNameSelect.value];
          }
          if (ret && lessonSelect.value != 0) {
            ret = e.lessonIndex == lesson[lessonSelect.value];
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
      parentLogic.update([SegmentShowLogic.findUnnecessarySegmentsId]);

      bodyViewHeight = getBodyViewHeight(missingSegmentIndex, baseBodyViewHeight);
      parentLogic.update([SegmentShowLogic.bodyId]);
    }

    // init select
    if (initContentNameSelect != null) {
      int index = contentNameOptions.indexOf(initContentNameSelect);
      if (index != -1) {
        contentNameSelect.value = index;
      }
    }
    if (initLessonSelect != null) {
      int index = lessonOptions.indexOf('${initLessonSelect + 1}');
      if (index != -1) {
        lessonSelect.value = index;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      trySearch();
    });

    Sheet.showBottomSheet(
      Get.context!,
      Stack(children: [
        Column(
          children: [
            RowWidget.buildSearch(search, searchController, focusNode: focusNode, onClose: Get.back, onSearch: trySearch),
            RowWidget.buildDividerWithoutColor(),
            if (missingSegmentIndex.isNotEmpty)
              GetBuilder<T>(
                  id: SegmentShowLogic.findUnnecessarySegmentsId,
                  builder: (_) {
                    if (missingSegmentIndex.isNotEmpty) {
                      return Column(
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
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
            GetBuilder<T>(
              id: SegmentShowLogic.bodyId,
              builder: (_) {
                var list = segmentShow;
                return SizedBox(
                  height: bodyViewHeight,
                  width: screenSize.width,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollStartNotification) {
                        if (focusNode.hasFocus) {
                          List<String> searches = StringUtil.splitN(searchKey, ",", 5);
                          if (searches.length == 5) {
                            contentNameSelect.value = int.parse(searches[0]);
                            lessonSelect.value = int.parse(searches[1]);
                            progressSelect.value = int.parse(searches[2]);
                            nextMonthSelect.value = int.parse(searches[3]);
                            search.value = searches[4];
                            searchController.text = search.value;
                          }
                          focusNode.unfocus();
                        }
                      }
                      return true;
                    },
                    child: ScrollablePositionedList.builder(
                      itemScrollController: itemScrollController,
                      itemPositionsListener: itemPositionsListener,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
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
                                        '${I18nKey.labelPosition.tr}: ${segment.toShortPos()}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ExpandableText(
                                      text: '${I18nKey.labelKey.tr}: ${segment.key}',
                                      limit: 40,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                                      selectText: search.value,
                                    ),
                                    const SizedBox(height: 8),
                                    ExpandableText(
                                      text: '${I18nKey.labelSegmentName.tr}: ${segment.segmentContent}',
                                      limit: 80,
                                      style: const TextStyle(fontSize: 14),
                                      selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                                      selectText: search.value,
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
                                          child: Text(
                                            '${I18nKey.labelProgress.tr}: ${segment.progress}',
                                            style: const TextStyle(fontSize: 12, color: Colors.green),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${I18nKey.labelSetNextLearnDate.tr}: ${segment.next.format()}',
                                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.more_vert,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        GetBuilder<T>(
            id: SegmentShowLogic.detailSearchId,
            builder: (_) {
              if (showSearchDetailPanel) {
                double searchViewHeight = 4.5 * (RowWidget.rowHeight + RowWidget.dividerHeight);
                return SizedBox(
                  height: searchViewHeight,
                  child: Column(
                    children: [
                      const SizedBox(height: RowWidget.rowHeight + RowWidget.dividerHeight),
                      Container(
                        height: searchViewHeight - RowWidget.rowHeight - RowWidget.dividerHeight,
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(Get.context!).scaffoldBackgroundColor,
                          border: const Border(bottom: BorderSide(color: Colors.grey)),
                        ),
                        child: ListView(
                          children: [
                            RowWidget.buildCupertinoPicker(
                              I18nKey.labelContent.tr,
                              contentNameOptions,
                              contentNameSelect,
                              changed: (index) {
                                contentNameSelect.value = index;
                              },
                            ),
                            RowWidget.buildDividerWithoutColor(),
                            RowWidget.buildCupertinoPicker(
                              I18nKey.labelLesson.tr,
                              lessonOptions,
                              lessonSelect,
                              changed: (index) {
                                lessonSelect.value = index;
                              },
                            ),
                            RowWidget.buildDividerWithoutColor(),
                            RowWidget.buildCupertinoPicker(
                              I18nKey.labelProgress.tr,
                              progressOptions,
                              progressSelect,
                              changed: (index) {
                                progressSelect.value = index;
                              },
                            ),
                            RowWidget.buildDividerWithoutColor(),
                            RowWidget.buildCupertinoPicker(
                              I18nKey.labelMonth.tr,
                              nextMonthOptions,
                              nextMonthSelect,
                              changed: (index) {
                                nextMonthSelect.value = index;
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
                                parentLogic.update([SegmentShowLogic.bodyId]);
                              },
                              pickWidth: 210.w,
                            ),
                            RowWidget.buildDividerWithoutColor(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
      ]),
      height: totalHeight,
    ).then((_) {
      searchController.dispose();
      focusNode.dispose();
    });
  }
}
