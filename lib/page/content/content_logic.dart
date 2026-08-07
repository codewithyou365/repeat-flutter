import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/query/chapter_query.dart';
import 'package:repeat_flutter/db/query/verse_query.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_brief_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/lazy_verse_today_prg_list.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_book_list.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_chapter_list.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/repeat_args.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'content_state.dart';
import 'logic/view_logic.dart';
import 'logic/view_logic_verse_list.dart';

class ContentLogic extends GetxController {
  static const String id = "ContentLogicId";
  final ContentState state = ContentState();
  List<ViewLogic?> viewList = [null, null, null];
  final SubList changeSub = [];

  @override
  void onInit() async {
    super.onInit();
    changeSub.on([EventTopic.reimportBook, EventTopic.deleteBook, EventTopic.deleteVerse], (_) {
      change();
    });

    var args = Get.arguments as ContentArgs;
    // 三个 tab 只共用一份"书本 id/名字/排序"和"每本书有哪几章"，都不带正文。
    // 正文由各自的窗口按滚动位置现取，页面关掉就跟着释放。
    var books = await BookBriefHelp.loadEnabled(Classroom.curr);
    var chapterIndexesByBook = await ChapterQuery.chapterIndexesByBook(Classroom.curr);
    late ViewLogicChapterList<ContentLogic> chapterList;
    var verseList = ViewLogicVerseList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onChapterModified: () async {
        await chapterList.refresh();
      },
      onNext: (List<int> verseIds, int index) async {
        if (!args.enableEnteringRepeatView) {
          return;
        }
        if (verseIds.isEmpty) {
          Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the verses"]));
          return;
        }
        var repeat = RepeatArgs(
          progresses: LazyVerseTodayPrgList(await VerseQuery.briefByIds(verseIds)),
          startIndex: index,
          repeatFlowType: RepeatType.browse,
          enableShowRecallButtons: false,
          showMode: ShowMode.edit,
        );
        await Nav.repeat.push(arguments: repeat);
      },
      parentLogic: this,
      books: books,
      chapterIndexesByBook: chapterIndexesByBook,
      initBookIdSelect: args.bookId,
      initChapterSelect: args.initChapterSelect,
      selectVerseKeyId: args.selectVerseKeyId,
    );
    chapterList = ViewLogicChapterList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onNext: (ChapterShow chapter) {
        state.tabIndex.value = 2;
        verseList.setBookSelectById(chapter.bookId);
        verseList.chapterSelect.value = chapter.chapterIndex + 1;
        update([ContentLogic.id]);
      },
      onChapterModified: () async {
        await verseList.refresh();
      },
      parentLogic: this,
      initBookIdSelect: args.bookId,
      initChapterSelect: args.initChapterSelect,
      books: books,
      chapterIndexesByBook: chapterIndexesByBook,
    );
    var bookList = ViewLogicBookList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onNext: (BookShow bookShow) {
        state.tabIndex.value = 1;
        chapterList.setBookSelectById(bookShow.bookId);
        update([ContentLogic.id]);
      },
      parentLogic: this,
      initBookIdSelect: args.bookId,
      books: books,
    );
    viewList[0] = bookList;
    viewList[1] = chapterList;
    viewList[2] = verseList;
    await verseList.loadValueOptions();
    state.tabIndex.value = args.defaultTap;
    update([ContentLogic.id]);
  }

  Future<void> change() async {
    final bookList = viewList[0] as ViewLogicBookList<ContentLogic>;
    final chapterList = viewList[1] as ViewLogicChapterList<ContentLogic>;
    final verseList = viewList[2] as ViewLogicVerseList<ContentLogic>;
    await bookList.refresh();
    await verseList.refresh();
    await chapterList.refresh();
    state.tabIndex.value = 0;
    update([ContentLogic.id]);
  }

  @override
  void onClose() {
    changeSub.off();
    for (var view in viewList) {
      if (view != null) {
        view.dispose();
      }
    }
  }
}
