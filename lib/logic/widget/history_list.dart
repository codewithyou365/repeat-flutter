import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date_time_util.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class HistoryList<T extends GetxController> {
  static const String bodyId = "HistoryList.bodyId";
  static const String detailSearchId = "HistoryList.searchId";

  final T parentLogic;

  HistoryList(this.parentLogic);

  Future<void> show(
    TextVersionType versionType,
    int versionId, {
    bool focus = false,
  }) async {
    List<TextVersion> historyData = await Db().db.textVersionDao.list(versionType, versionId);
    return await showSheet(
      historyData,
      focus: focus,
    );
  }

  Future<void> showSheet(
    List<ContentVersion> originalVersions, {
    bool focus = true,
  }) {
    RxString search = RxString("");
    bool showSearchDetailPanel = false;

    void tryUpdateDetailSearchPanel(bool newShow) {
      if (showSearchDetailPanel != newShow) {
        showSearchDetailPanel = newShow;
        parentLogic.update([HistoryList.detailSearchId]);
      }
    }

    final TextEditingController searchController = TextEditingController(text: search.value);
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        tryUpdateDetailSearchPanel(true);
      } else {
        tryUpdateDetailSearchPanel(false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focus) {
        focusNode.requestFocus();
      }
    });

    // for sorting and content
    List<ContentVersion> versions = List.from(originalVersions);
    RxInt selectedSortIndex = 0.obs;
    List<I18nKey> sortOptionKeys = [
      I18nKey.labelSortCreateDateDesc,
      I18nKey.labelSortCreateDateAsc,
    ];
    List<String> sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(versions, sortOptionKeys[selectedSortIndex.value]);

    // for height
    var mediaQueryData = MediaQuery.of(Get.context!);
    double bodyViewHeight = 0;
    final Size screenSize = mediaQueryData.size;
    final totalHeight = screenSize.height - mediaQueryData.padding.top;
    final baseBodyViewHeight = totalHeight - RowWidget.rowHeight - RowWidget.dividerHeight - Sheet.paddingVertical * 2;
    bodyViewHeight = baseBodyViewHeight;

    // Collect dates for filtering
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

    RxInt dateSelect = 0.obs;
    List<String> dateOptions = dates.map((d) {
      if (d == -1) {
        return I18nKey.labelAll.tr;
      }
      return formatDate(d);
    }).toList();

    final ItemScrollController itemScrollController = ItemScrollController();
    final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

    String genSearchKey() {
      return '${dateSelect.value},${search.value}';
    }

    String searchKey = genSearchKey();
    void trySearch() {
      String newSearchKey = genSearchKey();
      if (newSearchKey == searchKey) {
        return;
      }
      searchKey = newSearchKey;
      if (search.value.isNotEmpty || dateSelect.value != 0) {
        versions = originalVersions.where((e) {
          bool ret = true;
          if (ret && search.value.isNotEmpty) {
            ret = e.getContent().contains(search.value);
          }
          if (ret && dateSelect.value != 0) {
            DateTime createTime = e.getCreateTime();
            int date = createTime.year * 10000 + createTime.month * 100 + createTime.day;
            ret = date == dates[dateSelect.value];
          }
          return ret;
        }).toList();
      } else {
        versions = List.from(originalVersions);
      }
      sort(versions, sortOptionKeys[selectedSortIndex.value]);
      parentLogic.update([HistoryList.bodyId]);
    }

    return Sheet.showBottomSheet(
      Get.context!,
      Stack(children: [
        Column(
          children: [
            RowWidget.buildSearch(search, searchController, focusNode: focusNode, onClose: Get.back, onSearch: trySearch),
            RowWidget.buildDividerWithoutColor(),
            GetBuilder<T>(
              id: HistoryList.bodyId,
              builder: (_) {
                var list = versions;
                return SizedBox(
                  height: bodyViewHeight,
                  width: screenSize.width,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollStartNotification) {
                        if (focusNode.hasFocus) {
                          List<String> searches = StringUtil.splitN(searchKey, ",", 2);
                          if (searches.length == 2) {
                            dateSelect.value = int.parse(searches[0]);
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
                );
              },
            ),
          ],
        ),
        GetBuilder<T>(
            id: HistoryList.detailSearchId,
            builder: (_) {
              if (showSearchDetailPanel) {
                double searchViewHeight = 3 * (RowWidget.rowHeight + RowWidget.dividerHeight);
                return SizedBox(
                  height: searchViewHeight,
                  child: Column(
                    children: [
                      const SizedBox(height: RowWidget.rowHeight + RowWidget.dividerHeight / 2 + 1),
                      Container(
                        height: searchViewHeight - RowWidget.rowHeight - RowWidget.dividerHeight,
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
                              I18nKey.labelCreateTime.tr,
                              dateOptions,
                              dateSelect,
                              changed: (index) {
                                dateSelect.value = index;
                              },
                              pickWidth: 100.w,
                            ),
                            RowWidget.buildDividerWithoutColor(),
                            RowWidget.buildCupertinoPicker(
                              I18nKey.labelSortBy.tr,
                              sortOptions,
                              selectedSortIndex,
                              changed: (index) {
                                selectedSortIndex.value = index;
                                I18nKey key = sortOptionKeys[index];
                                sort(versions, key);
                                parentLogic.update([HistoryList.bodyId]);
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

  static void sort(List<ContentVersion> versions, I18nKey key) {
    switch (key) {
      case I18nKey.labelSortCreateDateAsc:
        versions.sort((a, b) => a.getCreateTime().compareTo(b.getCreateTime()));
        break;
      case I18nKey.labelSortCreateDateDesc:
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
