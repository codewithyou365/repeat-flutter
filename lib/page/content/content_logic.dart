import 'package:get/get.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_book_list.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_chapter_list.dart';

import 'content_state.dart';
import 'logic/view_logic.dart';
import 'logic/view_logic_verse_list.dart';

class ContentLogic extends GetxController {
  static const String id = "ContentLogicId";
  final ContentState state = ContentState();
  List<ViewLogic?> viewList = [null, null, null];

  @override
  void onInit() async {
    super.onInit();
    var args = Get.arguments as ContentArgs;
    List<BookShow> originalBookShow = await BookHelp.getBooks();
    List<ChapterShow> originalChapterShow = await ChapterHelp.getChapters();
    List<VerseShow> originalVerseShow = await VerseHelp.getVerses();
    late ViewLogicChapterList<ContentLogic> chapterList;
    var verseList = ViewLogicVerseList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onChapterModified: () async {
        chapterList.originalBookShow = await BookHelp.getBooks();
        chapterList.originalChapterShow = await ChapterHelp.getChapters();
        chapterList.collectData();
        chapterList.trySearch(force: true);
      },
      onCardTapDown: (List<String> selected) {
        //TODO
      },
      parentLogic: this,
      removeWarning: args.removeWarning,
      originalBookShow: originalBookShow,
      originalChapterShow: originalChapterShow,
      originalVerseShow: originalVerseShow,
      initContentNameSelect: args.bookName,
      initChapterSelect: args.initChapterSelect,
      selectVerseKeyId: args.selectVerseKeyId,
    );
    chapterList = ViewLogicChapterList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onCardTapDown: (List<String> selected) {
        state.tabIndex.value = 2;
        verseList.setBookSelectByName(selected.first);
        verseList.chapterSelect.value = int.parse(selected[1]) + 1;
        update([ContentLogic.id]);
      },
      onChapterModified: () async {
        verseList.originalBookShow = await BookHelp.getBooks();
        verseList.originalChapterShow = await ChapterHelp.getChapters();
        verseList.originalVerseShow = await VerseHelp.getVerses();
        verseList.collectData();
        verseList.trySearch(force: true);
      },
      parentLogic: this,
      removeWarning: args.removeWarning,
      initBookNameSelect: args.bookName,
      initChapterSelect: args.initChapterSelect,
      originalBookShow: originalBookShow,
      originalChapterShow: originalChapterShow,
    );
    var bookList = ViewLogicBookList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onCardTapDown: (List<String> selected) {
        state.tabIndex.value = 1;
        chapterList.setBookSelectByName(selected.first);
        update([ContentLogic.id]);
      },
      parentLogic: this,
      initContentNameSelect: args.bookName,
      originalBookShow: originalBookShow,
    );
    viewList[0] = bookList;
    viewList[1] = chapterList;
    viewList[2] = verseList;
    state.tabIndex.value = args.defaultTap;
    update([ContentLogic.id]);
  }

  @override
  void onClose() {
    for (var view in viewList) {
      if (view != null) {
        view.dispose();
      }
    }
  }
}
