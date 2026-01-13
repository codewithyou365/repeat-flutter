import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date_time_util.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class HistoryList<T extends GetxController> {
  static const String bodyId = "HistoryList.bodyId";

  final T parentLogic;

  HistoryList(this.parentLogic);

  Future<void> show(
    List<ContentVersion> originalVersions, {
    required RxBool focus,
  }) {
    RxString search = RxString("");
    bool showSearchDetailPanel = false;

    void tryUpdateDetailSearchPanel(bool newShow) {
      if (showSearchDetailPanel != newShow) {
        showSearchDetailPanel = newShow;
        parentLogic.update([HistoryList.bodyId]);
      }
    }

    final TextEditingController searchController = TextEditingController(text: search.value);
    final focusNode = FocusNode();
    focusNode.addListener(() {
      focus.value = focusNode.hasFocus;
      if (focusNode.hasFocus) {
        tryUpdateDetailSearchPanel(true);
      } else {
        tryUpdateDetailSearchPanel(false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focus.value) {
        focusNode.requestFocus();
      }
    });

    // for sorting and content
    List<ContentVersion> versions = List.from(originalVersions);
    int selectedSortIndex = 0;
    List<I18nKey> sortOptionKeys = [
      I18nKey.labelSortCreateTimeDesc,
      I18nKey.labelSortCreateTimeAsc,
    ];
    List<String> sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(versions, sortOptionKeys[selectedSortIndex]);

    // for height
    var mediaQueryData = MediaQuery.of(Get.context!);
    final Size screenSize = mediaQueryData.size;
    final totalHeight = screenSize.height - mediaQueryData.padding.top;
    final baseBodyViewHeight = totalHeight - RowWidget.rowHeight - RowWidget.dividerHeight - Sheet.paddingVertical * 2;
    final searchDetailPanelHeight = 2 * (RowWidget.rowHeight + RowWidget.dividerHeight);
    double getBodyViewHeight() {
      double ret = baseBodyViewHeight;
      if (showSearchDetailPanel) {
        ret = ret - searchDetailPanelHeight;
      }
      return ret;
    }

    List<int> dates = [];
    for (var version in versions) {
      final DateTime createTime = version.getCreateTime();
      int date = createTime.year * 10000 + createTime.month * 100 + createTime.day;
      if (!dates.contains(date)) {
        dates.add(date);
      }
    }
    dates.sort();
    dates.insert(0, -1); // Add "All" option

    int dateSelect = 0;
    List<String> dateOptions = dates.map((d) {
      if (d == -1) {
        return I18nKey.labelAll.tr;
      }
      return formatDate(d);
    }).toList();

    final ItemScrollController itemScrollController = ItemScrollController();
    final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

    String genSearchKey() {
      return '$dateSelect,${search.value},$selectedSortIndex';
    }

    String searchKey = genSearchKey();
    void trySearch() {
      String newSearchKey = genSearchKey();
      if (newSearchKey == searchKey) {
        return;
      }
      searchKey = newSearchKey;
      if (search.value.isNotEmpty || dateSelect != 0) {
        versions = originalVersions.where((e) {
          bool ret = true;
          if (ret && search.value.isNotEmpty) {
            ret = e.getContent().contains(search.value);
          }
          if (ret && dateSelect != 0) {
            DateTime createTime = e.getCreateTime();
            int date = createTime.year * 10000 + createTime.month * 100 + createTime.day;
            ret = date == dates[dateSelect];
          }
          return ret;
        }).toList();
      } else {
        versions = List.from(originalVersions);
      }
      sort(versions, sortOptionKeys[selectedSortIndex]);
      parentLogic.update([HistoryList.bodyId]);
    }

    return Sheet.showBottomSheet(
      Get.context!,
      GetBuilder<T>(
        id: HistoryList.bodyId,
        builder: (_) {
          Widget searchDetailPanel = const SizedBox.shrink();
          if (showSearchDetailPanel) {
            searchDetailPanel = SizedBox(
              height: searchDetailPanelHeight,
              child: Column(
                children: [
                  Container(
                    height: searchDetailPanelHeight,
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
                      children: [
                        RowWidget.buildCupertinoPicker(
                          title: I18nKey.labelCreateTime.tr,
                          options: dateOptions,
                          value: dateSelect,
                          changed: (index) {
                            dateSelect = index;
                            trySearch();
                          },
                          pickWidth: 100.w,
                        ),
                        RowWidget.buildDividerWithoutColor(),
                        RowWidget.buildCupertinoPicker(
                          title: I18nKey.labelSortBy.tr,
                          options: sortOptions,
                          value: selectedSortIndex,
                          changed: (index) {
                            selectedSortIndex = index;
                            trySearch();
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
          }
          var list = versions;
          return Column(
            children: [
              RowWidget.buildSearch(
                search,
                searchController,
                focus: focus,
                focusNode: focusNode,
                onClose: Get.back,
                onSearch: trySearch,
              ),
              RowWidget.buildDividerWithoutColor(),
              searchDetailPanel,
              SizedBox(
                height: getBodyViewHeight(),
                width: screenSize.width,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollStartNotification) {
                      if (focusNode.hasFocus) {
                        List<String> searches = StringUtil.splitN(searchKey, ",", 2);
                        if (searches.length == 2) {
                          dateSelect = int.parse(searches[0]);
                          search.value = searches[1];
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
                      final version = list[index];
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
                                      '${I18nKey.labelCreateTime.tr}: ${DateTimeUtil.format(version.getCreateTime())}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                  SizedBox(height: 8, width: screenSize.width),
                                  ExpandableText(
                                    title: "",
                                    text: version.getContent(),
                                    version: version.getVersion(),
                                    limit: 60,
                                    style: const TextStyle(fontSize: 14),
                                    selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                                    versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                    selectText: search.value,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: version.getContent()));
                                Snackbar.show(I18nKey.labelCopiedToClipboard.tr);
                              },
                              icon: const Icon(
                                Icons.copy,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      height: totalHeight,
    ).then((_) {
      searchController.dispose();
      focusNode.dispose();
    });
  }

  static void sort(List<ContentVersion> versions, I18nKey key) {
    switch (key) {
      case I18nKey.labelSortCreateTimeAsc:
        versions.sort((a, b) => a.getCreateTime().compareTo(b.getCreateTime()));
        break;
      case I18nKey.labelSortCreateTimeDesc:
        versions.sort((a, b) => b.getCreateTime().compareTo(a.getCreateTime()));
        break;
      default:
        break;
    }
  }

  String formatDate(int date) {
    String dateStr = date.toString();
    if (dateStr.length >= 8) {
      String year = dateStr.substring(0, 4);
      String month = dateStr.substring(4, 6);
      String day = dateStr.substring(6, 8);
      return '$year-$month-$day';
    }
    return dateStr;
  }
}
