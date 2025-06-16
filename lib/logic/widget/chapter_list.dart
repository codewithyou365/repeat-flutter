import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/chapter_key.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/history_list.dart';
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

class ChapterList<T extends GetxController> {
  static const String bodyId = "ChapterList.bodyId";
  static const String findUnnecessaryChaptersId = "ChapterList.findUnnecessaryChaptersId";
  static const String detailSearchId = "ChapterList.searchId";

  final T parentLogic;

  ChapterList(this.parentLogic);

  late HistoryList historyList = HistoryList<T>(parentLogic);

  Future<void> show({
    String? initContentNameSelect,
    int? initChapterSelect,
    int? selectChapterKeyId,
    bool focus = false,
    Future<void> Function()? removeWarning,
    Future<void> Function()? verseModified,
  }) async {
    List<ChapterShow> chapterShow = await ChapterHelp.getChapters();
    return await showSheet(
      chapterShow,
      initContentNameSelect: initContentNameSelect,
      initChapterSelect: initChapterSelect,
      selectChapterKeyId: selectChapterKeyId,
      focus: focus,
      removeWarning: removeWarning,
      verseModified: verseModified,
    );
  }

  Future<void> showSheet(
    List<ChapterShow> originalChapterShow, {
    String? initContentNameSelect,
    int? initChapterSelect,
    int? selectChapterKeyId,
    bool focus = true,
    Future<void> Function()? removeWarning,
    Future<void> Function()? verseModified,
  }) {
    // for search and controls
    RxString search = RxString("");
    bool showSearchDetailPanel = false;

    void tryUpdateDetailSearchPanel(bool newShow) {
      if (showSearchDetailPanel != newShow) {
        showSearchDetailPanel = newShow;
        parentLogic.update([ChapterList.detailSearchId]);
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
    List<ChapterShow> chapterShow = List.from(originalChapterShow);
    RxInt selectedSortIndex = 0.obs;
    List<I18nKey> sortOptionKeys = [
      I18nKey.labelSortPositionAsc,
      I18nKey.labelSortPositionDesc,
    ];
    List<String> sortOptions = sortOptionKeys.map((key) => key.tr).toList();
    sort(chapterShow, sortOptionKeys[selectedSortIndex.value]);

    // for collect search data, and missing chapter
    int missingChapterOffset = -1;
    List<int> missingChapterIndex = [];
    List<String> contentNameOptions = [];
    List<int> chapterIndex = [];
    collectDataFromChapters(
      missingChapterIndex,
      contentNameOptions,
      chapterIndex,
      chapterShow, // keep consistent with view below.
    );
    RxInt contentNameSelect = 0.obs;
    RxInt chapterIndexSelect = 0.obs;
    List<String> chapterOptions = chapterIndex.map((k) {
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
    bodyViewHeight = getBodyViewHeight(missingChapterIndex, baseBodyViewHeight);

    String genSearchKey() {
      return '${contentNameSelect.value},${chapterIndexSelect.value},${search.value}';
    }

    String searchKey = genSearchKey();
    void trySearch({bool force = false}) {
      String newSearchKey = genSearchKey();
      if (!force && newSearchKey == searchKey) {
        return;
      }
      searchKey = newSearchKey;
      if (search.value.isNotEmpty || contentNameSelect.value != 0 || chapterIndexSelect.value != 0) {
        chapterShow = originalChapterShow.where((e) {
          bool ret = true;
          if (ret && search.value.isNotEmpty) {
            ret = e.chapterContent.contains(search.value);
          }
          if (ret && contentNameSelect.value != 0) {
            ret = e.bookName == contentNameOptions[contentNameSelect.value];
          }
          if (ret && chapterIndexSelect.value != 0) {
            ret = e.chapterIndex == chapterIndex[chapterIndexSelect.value];
          }
          return ret;
        }).toList();
      } else {
        chapterShow = List.from(originalChapterShow);
      }
      sort(chapterShow, sortOptionKeys[selectedSortIndex.value]);
      refreshMissingChapterIndex(missingChapterIndex, chapterShow);

      bodyViewHeight = getBodyViewHeight(missingChapterIndex, baseBodyViewHeight);
      parentLogic.update([ChapterList.findUnnecessaryChaptersId, ChapterList.bodyId]);
    }

    // init select
    if (initContentNameSelect != null) {
      int index = contentNameOptions.indexOf(initContentNameSelect);
      if (index != -1) {
        contentNameSelect.value = index;
      }
    }
    if (initChapterSelect != null) {
      int index = chapterOptions.indexOf('${initChapterSelect + 1}');
      if (index != -1) {
        chapterIndexSelect.value = index;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      trySearch();
      int? selectedIndex;
      if (selectChapterKeyId != null) {
        ChapterShow? ls = ChapterHelp.getCache(selectChapterKeyId);
        if (ls != null) {
          selectedIndex = chapterShow.indexOf(ls);
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
    Future<void> refresh(ChapterKey chapterKey) async {
      await VerseHelp.getVerses(
        force: true,
        query: QueryChapter(
          bookSerial: chapterKey.bookSerial,
          minChapterIndex: chapterKey.chapterIndex,
        ),
      );
      if (verseModified != null) {
        await verseModified();
      }
      originalChapterShow = await ChapterHelp.getChapters(force: true);
      trySearch(force: true);
      await Get.find<GsCrLogic>().init();
    }

    delete({required ChapterShow chapter}) async {
      bool success = await showOverlay<bool>(() async {
        Map<String, dynamic> out = {};
        bool ok = await Db().db.chapterKeyDao.deleteNormalChapter(chapter.chapterKeyId, out);
        if (!ok) {
          return false;
        }
        ChapterKey chapterKey = out['chapterKey'] as ChapterKey;
        await refresh(chapterKey);
        return true;
      }, I18nKey.labelDeleting.tr);
      if (success) {
        Snackbar.show(I18nKey.labelDeleted.tr);
      }
      Get.back();
    }

    copy({required ChapterShow chapter, required bool below}) async {
      bool success = await showOverlay<bool>(() async {
        int chapterIndex = chapter.chapterIndex;
        if (below) {
          chapterIndex++;
        }
        Map<String, dynamic> out = {};
        var ok = await Db().db.chapterKeyDao.addChapter(chapter, chapterIndex, out);
        if (!ok) {
          return false;
        }
        ChapterKey chapterKey = out['chapterKey'] as ChapterKey;
        await refresh(chapterKey);
        return true;
      }, I18nKey.labelCopying.tr);
      if (success) {
        Snackbar.show(I18nKey.labelCopied.tr);
      }
      Get.back();
    }

    return Sheet.showBottomSheet(
      Get.context!,
      Stack(children: [
        Column(
          children: [
            RowWidget.buildSearch(search, searchController, focusNode: focusNode, onClose: Get.back, onSearch: trySearch),
            RowWidget.buildDividerWithoutColor(),
            if (missingChapterIndex.isNotEmpty)
              GetBuilder<T>(
                  id: ChapterList.findUnnecessaryChaptersId,
                  builder: (_) {
                    if (missingChapterIndex.isNotEmpty) {
                      return Column(
                        children: [
                          RowWidget.buildWidgetsWithTitle(I18nKey.labelFindUnnecessaryChapters.tr, [
                            IconButton(
                                onPressed: () {
                                  if (missingChapterOffset - 1 < 0) {
                                    missingChapterOffset = 0;
                                  } else {
                                    missingChapterOffset--;
                                  }
                                  itemScrollController.scrollTo(
                                    index: missingChapterIndex[missingChapterOffset],
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                icon: const Icon(Icons.arrow_back)),
                            IconButton(
                                onPressed: () {
                                  if (missingChapterOffset + 1 >= missingChapterIndex.length) {
                                    missingChapterOffset = missingChapterIndex.length - 1;
                                  } else {
                                    missingChapterOffset++;
                                  }
                                  itemScrollController.scrollTo(
                                    index: missingChapterIndex[missingChapterOffset],
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
              id: ChapterList.bodyId,
              builder: (_) {
                var list = chapterShow;
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
                            chapterIndexSelect.value = int.parse(searches[1]);
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
                        final chapter = list[index];
                        return Card(
                          color: chapter.missing ? Colors.red : null,
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
                                        '${I18nKey.labelChapterName.tr}: ${chapter.toPos()}',
                                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                                      ),
                                    ),
                                    SizedBox(height: 8, width: screenSize.width),
                                    ExpandableText(
                                      title: I18nKey.labelChapterName.tr,
                                      text: ': ${chapter.chapterContent}',
                                      version: chapter.chapterContentVersion,
                                      limit: 60,
                                      style: const TextStyle(fontSize: 14),
                                      selectedStyle: search.value.isNotEmpty ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null,
                                      versionStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                      selectText: search.value,
                                      onEdit: () {
                                        focusNode.unfocus();
                                        var contentM = jsonDecode(chapter.chapterContent);
                                        var content = const JsonEncoder.withIndent(' ').convert(contentM);
                                        Editor.show(
                                          Get.context!,
                                          I18nKey.labelChapterName.tr,
                                          content,
                                          (str) async {
                                            await Db().db.chapterKeyDao.updateChapterContent(chapter.chapterKeyId, str);
                                            parentLogic.update([ChapterList.bodyId]);
                                          },
                                          qrPagePath: Nav.scan.path,
                                          onHistory: () {
                                            historyList.show(TextVersionType.chapterContent, chapter.chapterKeyId);
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
                                  if (chapter.missing)
                                    IconButton(
                                      onPressed: () {
                                        MsgBox.yesOrNo(
                                          title: I18nKey.labelDelete.tr,
                                          desc: I18nKey.labelDeleteChapter.tr,
                                          yes: () {
                                            showTransparentOverlay(() async {
                                              var ok = await Db().db.chapterKeyDao.deleteAbnormalChapter(chapter.chapterKeyId);
                                              if (ok == false) {
                                                return;
                                              }
                                              ChapterHelp.deleteCache(chapter.chapterKeyId);
                                              chapterShow.removeWhere((element) => element.chapterKeyId == chapter.chapterKeyId);

                                              var contentId2Missing = refreshMissingChapterIndex(missingChapterIndex, chapterShow);
                                              var warning = contentId2Missing[chapter.bookId] ?? false;
                                              if (warning == false) {
                                                await Db().db.bookDao.updateBookWarningForChapter(chapter.bookId, warning, DateTime.now().millisecondsSinceEpoch);
                                                if (removeWarning != null) {
                                                  await removeWarning();
                                                }
                                              }
                                              parentLogic.update([ChapterList.findUnnecessaryChaptersId, ChapterList.bodyId]);
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
                                            yes: () => delete(chapter: chapter),
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
                                                  onPressed: () => copy(chapter: chapter, below: false),
                                                ),
                                                MsgBox.button(
                                                  text: I18nKey.btnBelow.tr,
                                                  onPressed: () => copy(chapter: chapter, below: true),
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
            id: ChapterList.detailSearchId,
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
                              I18nKey.labelBook.tr,
                              contentNameOptions,
                              contentNameSelect,
                              changed: (index) {
                                contentNameSelect.value = index;
                              },
                            ),
                            RowWidget.buildDividerWithoutColor(),
                            RowWidget.buildCupertinoPicker(
                              I18nKey.labelChapter.tr,
                              chapterOptions,
                              chapterIndexSelect,
                              changed: (index) {
                                chapterIndexSelect.value = index;
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
                                sort(chapterShow, key);
                                parentLogic.update([ChapterList.bodyId]);
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

  static Map<int, bool> refreshMissingChapterIndex(
    List<int> missingChapterIndex,
    List<ChapterShow> chapterShow,
  ) {
    missingChapterIndex.clear();

    Map<int, bool> contentId2Missing = {};
    for (int i = 0; i < chapterShow.length; i++) {
      var v = chapterShow[i];
      if (v.missing) {
        contentId2Missing[v.bookId] = true;
        missingChapterIndex.add(i);
      }
    }
    return contentId2Missing;
  }

  static void collectDataFromChapters(
    List<int> missingChapterIndex,
    List<String> contentName,
    List<int> chapterIndex,
    List<ChapterShow> chapterShow,
  ) {
    for (int i = 0; i < chapterShow.length; i++) {
      var v = chapterShow[i];
      if (v.missing) {
        missingChapterIndex.add(i);
      }
      if (!contentName.contains(v.bookName)) {
        contentName.add(v.bookName);
      }
      if (!chapterIndex.contains(v.chapterIndex)) {
        chapterIndex.add(v.chapterIndex);
      }
    }
    chapterIndex.sort();
    contentName.insert(0, I18nKey.labelAll.tr);
    chapterIndex.insert(0, -1);
  }

  static sort(List<ChapterShow> chapterShow, I18nKey key) {
    switch (key) {
      case I18nKey.labelSortPositionAsc:
        chapterShow.sort((a, b) => a.toSort().compareTo(b.toSort()));
        break;
      case I18nKey.labelSortPositionDesc:
        chapterShow.sort((a, b) => b.toSort().compareTo(a.toSort()));
        break;
      default:
        break;
    }
  }

  static double getBodyViewHeight(List<int> missingChapterIndex, double baseBodyViewHeight) {
    if (missingChapterIndex.isNotEmpty) {
      return baseBodyViewHeight - RowWidget.rowHeight - RowWidget.dividerHeight;
    } else {
      return baseBodyViewHeight;
    }
  }
}
