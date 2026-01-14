import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
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
    changeSub.on([EventTopic.reimportBook, EventTopic.deleteBook], (_) {
      change();
    });

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
      onNext: (List<VerseShow> verseShows, int index) async {
        if (!args.enableEnteringRepeatView) {
          return;
        }
        await Db().db.verseTodayPrgDao.deleteByType(TodayPrgType.justView.index);
        List<VerseTodayPrg> verseTodayPrg = [];
        for (int i = 0; i < verseShows.length; i++) {
          var verseShow = verseShows[i];
          verseTodayPrg.add(
            VerseTodayPrg(
              classroomId: Classroom.curr,
              bookId: verseShow.bookId,
              chapterId: verseShow.chapterId,
              verseId: verseShow.verseId,
              time: 0,
              type: TodayPrgType.justView.index,
              sort: i,
              progress: 0,
              viewTime: DateTime.now(),
              reviewCount: 0,
              reviewCreateDate: Date(0),
              finish: false,
            ),
          );
        }
        await Db().db.verseTodayPrgDao.insertsOrFail(verseTodayPrg);

        var p = await Db().db.verseTodayPrgDao.findByType(TodayPrgType.justView.index);
        if (p.isEmpty) {
          Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant insert the verses"]));
          return;
        }
        var repeat = RepeatArgs(
          progresses: p,
          startIndex: index,
          repeatType: RepeatType.justView,
          enableShowRecallButtons: false,
          showMode: ShowMode.edit,
        );
        await Nav.repeat.push(arguments: repeat);
        await Db().db.verseTodayPrgDao.deleteByType(TodayPrgType.justView.index);
      },
      parentLogic: this,
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
      onNext: (ChapterShow chapter) {
        state.tabIndex.value = 2;
        verseList.setBookSelectByName(chapter.bookName);
        verseList.chapterSelect.value = chapter.chapterIndex + 1;
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
      initBookNameSelect: args.bookName,
      initChapterSelect: args.initChapterSelect,
      originalBookShow: originalBookShow,
      originalChapterShow: originalChapterShow,
    );
    var bookList = ViewLogicBookList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onNext: (BookShow bookShow) {
        state.tabIndex.value = 1;
        chapterList.setBookSelectByName(bookShow.name);
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

  Future<void> change() async {
    final bookList = viewList[0] as ViewLogicBookList<ContentLogic>;
    final chapterList = viewList[1] as ViewLogicChapterList<ContentLogic>;
    final verseList = viewList[2] as ViewLogicVerseList<ContentLogic>;
    bookList.originalBookShow = await BookHelp.getBooks();
    bookList.bookShow = bookList.originalBookShow;
    bookList.collectData();
    bookList.trySearch(force: true);

    verseList.originalBookShow = await BookHelp.getBooks();
    verseList.originalChapterShow = await ChapterHelp.getChapters();
    verseList.originalVerseShow = await VerseHelp.getVerses();
    verseList.collectData();
    verseList.trySearch(force: true);

    chapterList.originalBookShow = await BookHelp.getBooks();
    chapterList.originalChapterShow = await ChapterHelp.getChapters();
    chapterList.collectData();
    chapterList.trySearch(force: true);
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
