import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SegmentShowLogic<T extends GetxController> {
  static const String id = "SegmentShowLogic";
  static const String headerId = "SegmentShowHeaderLogic";

  final T parentLogic;

  SegmentShowLogic(this.parentLogic);

  void collectDataFromSegments(
    List<int> missingSegmentIndex,
    List<SegmentShow> segmentShow, {
    List<String>? contentName,
    List<int>? lesson,
    List<int>? progress,
    List<int>? nextMonth,
  }) {
    if (contentName != null) {
      contentName.add(I18nKey.labelAll.tr);
    }
    if (lesson != null) {
      lesson.add(-1);
    }
    if (progress != null) {
      progress.add(-1);
    }
    if (nextMonth != null) {
      nextMonth.add(-1);
    }

    missingSegmentIndex.clear();
    for (int i = 0; i < segmentShow.length; i++) {
      var v = segmentShow[i];
      if (v.missing) {
        missingSegmentIndex.add(i);
        if (contentName != null) {
          if (!contentName.contains(v.contentName)) {
            contentName.add(v.contentName);
          }
        }
      }
      if (lesson != null) {
        if (!lesson.contains(v.lessonIndex)) {
          lesson.add(v.lessonIndex);
        }
      }
      if (progress != null) {
        if (!progress.contains(v.progress)) {
          progress.add(v.progress);
        }
      }
      if (nextMonth != null) {
        int month = v.next.value ~/ 100;
        if (!nextMonth.contains(month)) {
          nextMonth.add(month);
        }
      }
    }
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

  show(List<SegmentShow> originalSegmentShow) {
    // for search and controls
    RxString search = RxString("");
    RxBool showSearchDetailPanel = false.obs;
    final TextEditingController controller = TextEditingController(text: search.value);
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        showSearchDetailPanel.value = true;
      } else {
        showSearchDetailPanel.value = false;
      }
    });

    // for collect search data, and missing segment
    int missingSegmentOffset = -1;
    List<int> missingSegmentIndex = [];
    List<String> contentNameOptions = [];
    List<int> lesson = [];
    List<int> progress = [];
    List<int> nextMonth = [];
    collectDataFromSegments(
      missingSegmentIndex,
      contentName: contentNameOptions,
      lesson: lesson,
      progress: progress,
      nextMonth: nextMonth,
      originalSegmentShow,
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

    // for height
    var mediaQueryData = MediaQuery.of(Get.context!);
    double bodyViewHeight = 0;
    final Size screenSize = mediaQueryData.size;
    final totalHeight = screenSize.height - mediaQueryData.padding.top;
    final baseBodyViewHeight = totalHeight - RowWidget.rowHeight - RowWidget.dividerHeight - Sheet.paddingVertical * 2;
    bodyViewHeight = getBodyViewHeight(missingSegmentIndex, baseBodyViewHeight);

    Sheet.showBottomSheet(
      Get.context!,
      Stack(children: [
        Column(
          children: [
            RowWidget.buildSearch(search, controller, focusNode: focusNode, onClose: Get.back, onSearch: () {
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
              collectDataFromSegments(missingSegmentIndex, segmentShow);
              parentLogic.update([SegmentShowLogic.headerId]);

              bodyViewHeight = getBodyViewHeight(missingSegmentIndex, baseBodyViewHeight);
              parentLogic.update([SegmentShowLogic.id]);
            }),
            RowWidget.buildDividerWithoutColor(),
            if (missingSegmentIndex.isNotEmpty)
              GetBuilder<T>(
                  id: SegmentShowLogic.headerId,
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
              id: SegmentShowLogic.id,
              builder: (_) {
                var list = segmentShow;
                return SizedBox(
                  height: bodyViewHeight,
                  width: screenSize.width,
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
                );
              },
            ),
          ],
        ),
        Obx(() {
          if (showSearchDetailPanel.value) {
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
                      border: Border(bottom: BorderSide(color: Colors.grey)),
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
                            parentLogic.update([SegmentShowLogic.id]);
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
      controller.dispose();
      focusNode.dispose();
    });
  }
}
