import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'editor.dart';

class LessonList<T extends GetxController> {
  static const String bodyId = "LessonList.bodyId";
  static const String findUnnecessaryLessonsId = "LessonList.findUnnecessaryLessonsId";
  static const String detailSearchId = "LessonList.searchId";

  final T parentLogic;

  LessonList(this.parentLogic);

  late HistoryList historyList = HistoryList<T>(parentLogic);

  Future<void> show({
    String? initContentNameSelect,
    int? initLessonSelect,
    int? selectLessonKeyId,
    bool focus = false,
    Future<void> Function()? removeWarning,
  }) async {
    List<LessonShow> lessonShow = await LessonHelp.getLessons();
    return await showSheet(
      lessonShow,
      initContentNameSelect: initContentNameSelect,
      initLessonSelect: initLessonSelect,
      selectLessonKeyId: selectLessonKeyId,
      focus: focus,
      removeWarning: removeWarning,
    );
  }

  Future<void> showSheet(
    List<LessonShow> originalLessonShow, {
    String? initContentNameSelect,
    int? initLessonSelect,
    int? selectLessonKeyId,
    bool focus = true,
    Future<void> Function()? removeWarning,
  }) {
    // for search and controls
    RxString search = RxString("");
    bool showSearchDetailPanel = false;

    void tryUpdateDetailSearchPanel(bool newShow) {
      if (showSearchDetailPanel != newShow) {
        showSearchDetailPanel = newShow;
        parentLogic.update([LessonList.detailSearchId]);
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
    List<LessonShow> lessonShow = List.from(originalLessonShow);
    RxInt selectedSortIndex = 0.obs;
    List<I18nKey> sortOptionKeys = [
      I18nKey.labelSortPositionAsc,
      I18nKey.labelSortPositionDesc,
    ];
    List<String> sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(lessonShow, sortOptionKeys[selectedSortIndex.value]);

    // for collect search data, and missing lesson
    int missingLessonOffset = -1;
    List<int> missingLessonIndex = [];
    List<String> contentNameOptions = [];
    List<int> lessonIndex = [];
    collectDataFromLessons(
      missingLessonIndex,
      contentNameOptions,
      lessonIndex,
      lessonShow, // keep consistent with view below.
    );
    RxInt contentNameSelect = 0.obs;
    RxInt lessonIndexSelect = 0.obs;
    List<String> lessonOptions = lessonIndex.map((k) {
      if (k == -1) {
        return I18nKey.labelAll.tr;
      }
      return '${k + 1}';
    }).toList();

    final ItemScrollController itemScrollController = ItemScrollController();
    final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

    // for height
    var mediaQueryData = MediaQuery.of(Get.context!);
    double bodyViewHeight = 0;
    final Size screenSize = mediaQueryData.size;
    final totalHeight = screenSize.height - mediaQueryData.padding.top;
    final baseBodyViewHeight = totalHeight - RowWidget.rowHeight - RowWidget.dividerHeight - Sheet.paddingVertical * 2;
    bodyViewHeight = getBodyViewHeight(missingLessonIndex, baseBodyViewHeight);

    String genSearchKey() {
      return '${contentNameSelect.value},${lessonIndexSelect.value},${search.value}';
    }

    String searchKey = genSearchKey();
    void trySearch() {
      String newSearchKey = genSearchKey();
      if (newSearchKey == searchKey) {
        return;
      }
      searchKey = newSearchKey;
      if (search.value.isNotEmpty || contentNameSelect.value != 0 || lessonIndexSelect.value != 0) {
        lessonShow = originalLessonShow.where((e) {
          bool ret = true;
          if (ret && search.value.isNotEmpty) {
            ret = e.lessonContent.contains(search.value);
          }
          if (ret && contentNameSelect.value != 0) {
            ret = e.contentName == contentNameOptions[contentNameSelect.value];
          }
          if (ret && lessonIndexSelect.value != 0) {
            ret = e.lessonIndex == lessonIndex[lessonIndexSelect.value];
          }
          return ret;
        }).toList();
      } else {
        lessonShow = List.from(originalLessonShow);
      }
      sort(lessonShow, sortOptionKeys[selectedSortIndex.value]);
      refreshMissingLessonIndex(missingLessonIndex, lessonShow);

      bodyViewHeight = getBodyViewHeight(missingLessonIndex, baseBodyViewHeight);
      parentLogic.update([LessonList.findUnnecessaryLessonsId, LessonList.bodyId]);
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
        lessonIndexSelect.value = index;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      trySearch();
      int? selectedIndex;
      if (selectLessonKeyId != null) {
        LessonShow? ls = LessonHelp.getCache(selectLessonKeyId);
        if (ls != null) {
          selectedIndex = lessonShow.indexOf(ls);
        }
      }
      if (selectedIndex != null) {
        itemScrollController.scrollTo(
          index: selectedIndex,
          duration: const Duration(milliseconds: 10),
          curve: Curves.easeInOut,
        );
      }
    });

    return Sheet.showBottomSheet(
      Get.context!,
      Stack(children: [
        Column(
          children: [
            RowWidget.buildSearch(search, searchController, focusNode: focusNode, onClose: Get.back, onSearch: trySearch),
            RowWidget.buildDividerWithoutColor(),
            if (missingLessonIndex.isNotEmpty)
              GetBuilder<T>(
                  id: LessonList.findUnnecessaryLessonsId,
                  builder: (_) {
                    if (missingLessonIndex.isNotEmpty) {
                      return Column(
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
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
            GetBuilder<T>(
              id: LessonList.bodyId,
              builder: (_) {
                var list = lessonShow;
                return SizedBox(
                  height: bodyViewHeight,
                  width: screenSize.width,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollStartNotification) {
                        if (focusNode.hasFocus) {
                          List<String> searches = StringUtil.splitN(searchKey, ",", 3);
                          if (searches.length == 3) {
                            contentNameSelect.value = int.parse(searches[0]);
                            lessonIndexSelect.value = int.parse(searches[1]);
                            search.value = searches[2];
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
                                        '${I18nKey.labelLessonName.tr}: ${lesson.toPos()}',
                                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
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
                                        focusNode.unfocus();
                                        var contentM = jsonDecode(lesson.lessonContent);
                                        var content = const JsonEncoder.withIndent(' ').convert(contentM);
                                        Editor.show(
                                          Get.context!,
                                          I18nKey.labelLessonName.tr,
                                          content,
                                          (str) async {
                                            await Db().db.lessonKeyDao.updateLessonContent(lesson.lessonKeyId, str);
                                            parentLogic.update([LessonList.bodyId]);
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
                                          I18nKey.labelDelete.tr,
                                          I18nKey.labelDeleteLesson.tr,
                                          yes: () {
                                            showTransparentOverlay(() async {
                                              var ok = await Db().db.lessonKeyDao.delete(lesson.lessonKeyId);
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
                                                  await removeWarning();
                                                }
                                              }
                                              parentLogic.update([LessonList.findUnnecessaryLessonsId, LessonList.bodyId]);
                                              Get.back();
                                            });
                                          },
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_forever,
                                      ),
                                    ),
                                ],
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
            id: LessonList.detailSearchId,
            builder: (_) {
              if (showSearchDetailPanel) {
                double searchViewHeight = 4 * (RowWidget.rowHeight + RowWidget.dividerHeight);
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
                              lessonIndexSelect,
                              changed: (index) {
                                lessonIndexSelect.value = index;
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
                                sort(lessonShow, key);
                                parentLogic.update([LessonList.bodyId]);
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

  static Map<int, bool> refreshMissingLessonIndex(
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

  static void collectDataFromLessons(
    List<int> missingLessonIndex,
    List<String> contentName,
    List<int> lessonIndex,
    List<LessonShow> lessonShow,
  ) {
    for (int i = 0; i < lessonShow.length; i++) {
      var v = lessonShow[i];
      if (v.missing) {
        missingLessonIndex.add(i);
      }
      if (!contentName.contains(v.contentName)) {
        contentName.add(v.contentName);
      }
      if (!lessonIndex.contains(v.lessonIndex)) {
        lessonIndex.add(v.lessonIndex);
      }
    }
    lessonIndex.sort();
    contentName.insert(0, I18nKey.labelAll.tr);
    lessonIndex.insert(0, -1);
  }

  static sort(List<LessonShow> lessonShow, I18nKey key) {
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

  static double getBodyViewHeight(List<int> missingLessonIndex, double baseBodyViewHeight) {
    if (missingLessonIndex.isNotEmpty) {
      return baseBodyViewHeight - RowWidget.rowHeight - RowWidget.dividerHeight;
    } else {
      return baseBodyViewHeight;
    }
  }
}
