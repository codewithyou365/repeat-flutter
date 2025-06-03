import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
import 'package:repeat_flutter/logic/widget/lesson_list.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'editor.dart';

class SegmentList<T extends GetxController> {
  static const String bodyId = "SegmentList.bodyId";
  static const String findUnnecessarySegmentsId = "SegmentList.findUnnecessarySegmentsId";
  static const String detailSearchId = "SegmentList.searchId";

  final T parentLogic;

  SegmentList(this.parentLogic);

  late HistoryList historyList = HistoryList<T>(parentLogic);
  late LessonList lessonList = LessonList<T>(parentLogic);

  Future<void> show({
    String? initContentNameSelect,
    int? initLessonSelect,
    int? selectSegmentKeyId,
    bool focus = false,
    Future<void> Function()? removeWarning,
  }) async {
    List<SegmentShow> segmentShow = await SegmentHelp.getSegments();
    return await _showSheet(
      segmentShow,
      initContentNameSelect: initContentNameSelect,
      initLessonSelect: initLessonSelect,
      selectSegmentKeyId: selectSegmentKeyId,
      focus: focus,
      removeWarning: removeWarning,
    );
  }

  Future<void> _showSheet(
    List<SegmentShow> originalSegmentShow, {
    String? initContentNameSelect,
    int? initLessonSelect,
    int? selectSegmentKeyId,
    bool focus = true,
    Future<void> Function()? removeWarning,
  }) {
    // for search and controls
    RxString search = RxString("");
    bool showSearchDetailPanel = false;

    void tryUpdateDetailSearchPanel(bool newShow) {
      if (showSearchDetailPanel != newShow) {
        showSearchDetailPanel = newShow;
        parentLogic.update([SegmentList.detailSearchId]);
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
    void trySearch({force = false}) {
      String newSearchKey = genSearchKey();
      if (!force && newSearchKey == searchKey) {
        return;
      }
      searchKey = newSearchKey;
      if (search.value.isNotEmpty || contentNameSelect.value != 0 || lessonSelect.value != 0 || progressSelect.value != 0 || nextMonthSelect.value != 0) {
        segmentShow = originalSegmentShow.where((e) {
          bool ret = true;
          if (ret && search.value.isNotEmpty) {
            ret = e.segmentContent.contains(search.value);
            if (ret == false) {
              ret = e.segmentNote.contains(search.value);
            }
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

      bodyViewHeight = getBodyViewHeight(missingSegmentIndex, baseBodyViewHeight);
      parentLogic.update([SegmentList.findUnnecessarySegmentsId, SegmentList.bodyId]);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      trySearch();
      if (selectSegmentKeyId != null) {
        scrollTo(selectSegmentKeyId);
      }
    });

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

    return Sheet.showBottomSheet(
      Get.context!,
      Stack(children: [
        Column(
          children: [
            RowWidget.buildSearch(search, searchController, focusNode: focusNode, onClose: Get.back, onSearch: trySearch),
            RowWidget.buildDividerWithoutColor(),
            if (missingSegmentIndex.isNotEmpty)
              GetBuilder<T>(
                  id: SegmentList.findUnnecessarySegmentsId,
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
              id: SegmentList.bodyId,
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          var lesson = await Db().db.lessonDao.one(Classroom.curr, segment.contentSerial, segment.lessonIndex);
                                          if (lesson != null) {
                                            lessonList.show(
                                              initContentNameSelect: initContentNameSelect,
                                              selectLessonKeyId: lesson.lessonKeyId,
                                              segmentModified: () async {
                                                originalSegmentShow = await SegmentHelp.getSegments();
                                                trySearch(force: true);
                                              },
                                            );
                                          }
                                        },
                                        child: Text.rich(
                                          TextSpan(children: [
                                            TextSpan(
                                              text: '${I18nKey.labelLessonName.tr}: ${segment.toLessonPos()}',
                                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                                            ),
                                            TextSpan(
                                              text: segment.toSegmentPos(),
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ]),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8, width: screenSize.width),
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
                                        focusNode.unfocus();
                                        var contentM = jsonDecode(segment.segmentContent);
                                        var content = const JsonEncoder.withIndent(' ').convert(contentM);
                                        Editor.show(
                                          Get.context!,
                                          I18nKey.labelSegmentName.tr,
                                          content,
                                          (str) async {
                                            await Db().db.scheduleDao.tUpdateSegmentContent(segment.segmentKeyId, str);
                                            parentLogic.update([SegmentList.bodyId]);
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
                                        focusNode.unfocus();
                                        Editor.show(
                                          Get.context!,
                                          I18nKey.labelNote.tr,
                                          segment.segmentNote,
                                          (str) async {
                                            await Db().db.scheduleDao.tUpdateSegmentNote(segment.segmentKeyId, str);
                                            parentLogic.update([SegmentList.bodyId]);
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
                                                  await removeWarning();
                                                }
                                              }
                                              parentLogic.update([SegmentList.findUnnecessarySegmentsId, SegmentList.bodyId]);
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
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        GetBuilder<T>(
            id: SegmentList.detailSearchId,
            builder: (_) {
              if (showSearchDetailPanel) {
                double searchViewHeight = 4.5 * (RowWidget.rowHeight + RowWidget.dividerHeight);
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
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 4),
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
                              I18nKey.labelLessonName.tr,
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
                                parentLogic.update([SegmentList.bodyId]);
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

  static void collectDataFromSegments(
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

  static double getBodyViewHeight(List<int> missingSegmentIndex, double baseBodyViewHeight) {
    if (missingSegmentIndex.isNotEmpty) {
      return baseBodyViewHeight - RowWidget.rowHeight - RowWidget.dividerHeight;
    } else {
      return baseBodyViewHeight;
    }
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
      parentLogic.update([SegmentList.bodyId]);
    });
  }
}
