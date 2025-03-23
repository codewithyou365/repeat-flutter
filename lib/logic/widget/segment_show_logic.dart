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

  int missingSegmentOffset = -1;
  List<int> missingSegmentIndex = [];

  SegmentShowLogic(this.parentLogic);

  refreshMissingSegmentIndex(List<SegmentShow> segmentShow) {
    missingSegmentIndex = [];
    for (int i = 0; i < segmentShow.length; i++) {
      if (segmentShow[i].missing) {
        missingSegmentIndex.add(i);
      }
    }
    parentLogic.update([SegmentShowLogic.headerId]);
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

  double getBodyViewHeight(double baseBodyViewHeight) {
    if (missingSegmentIndex.isNotEmpty) {
      return baseBodyViewHeight - RowWidget.rowHeight;
    } else {
      return baseBodyViewHeight;
    }
  }

  show(List<SegmentShow> originalSegmentShow) {
    RxString search = RxString("");
    List<SegmentShow> segmentShow = List.from(originalSegmentShow);
    final GlobalKey topColumn = GlobalKey();
    double bodyViewHeight = 0;
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
    refreshMissingSegmentIndex(segmentShow);
    final ItemScrollController itemScrollController = ItemScrollController();
    final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

    var mediaQueryData = MediaQuery.of(Get.context!);
    final Size screenSize = mediaQueryData.size;
    final totalHeight = screenSize.height - mediaQueryData.padding.top;
    final baseBodyViewHeight = totalHeight - 2 * RowWidget.rowHeight - 2 * 16 - Sheet.paddingVertical * 2;
    bodyViewHeight = getBodyViewHeight(baseBodyViewHeight);
    RxBool extendSearch = false.obs;
    Sheet.showBottomSheet(
        Get.context!,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              key: topColumn,
              children: [
                RowWidget.buildSearch(search,
                    prefix: Obx(() {
                      return IconButton(
                        onPressed: () {
                          extendSearch.value = !extendSearch.value;
                        },
                        icon: extendSearch.value ? const Icon(Icons.expand_more) : const Icon(Icons.expand_less),
                      );
                    }),
                    onClose: Get.back,
                    onSearch: () {
                      if (search.value.isNotEmpty) {
                        segmentShow = originalSegmentShow.where((e) => e.segmentContent.contains(search.value)).toList();
                      } else {
                        segmentShow = List.from(originalSegmentShow);
                      }
                      sort(segmentShow, sortOptionKeys[selectedSortIndex.value]);
                      refreshMissingSegmentIndex(segmentShow);
                      bodyViewHeight = getBodyViewHeight(baseBodyViewHeight);
                      print("123");
                      parentLogic.update([SegmentShowLogic.id]);
                    }),
                if (missingSegmentIndex.isNotEmpty)
                  GetBuilder<T>(
                      id: SegmentShowLogic.headerId,
                      builder: (_) {
                        if (missingSegmentIndex.isNotEmpty) {
                          return RowWidget.buildWidgetsWithTitle(I18nKey.labelFindUnnecessarySegments.tr, [
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
                          ]);
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                RowWidget.buildDividerWithoutColor(),
                RowWidget.buildCupertinoPicker(
                  I18nKey.labelSortBy.tr,
                  sortOptions,
                  selectedSortIndex,
                  changed: (index) {
                    selectedSortIndex.value = index;
                    I18nKey key = sortOptionKeys[index];
                    sort(segmentShow, key);
                    refreshMissingSegmentIndex(segmentShow);
                    parentLogic.update([SegmentShowLogic.id]);
                  },
                  pickWidth: 210.w,
                ),
                RowWidget.buildDividerWithoutColor(),
              ],
            ),
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
        height: totalHeight);
  }
}
