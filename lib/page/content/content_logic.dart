import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_book_list.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_chapter_list.dart';
import 'package:repeat_flutter/page/repeat/repeat_args.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

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
      onCardTapDown: (VerseShow verseShow) async {
        Verse? verse = await Db().db.verseDao.one(Classroom.curr, verseShow.bookSerial, verseShow.chapterIndex, verseShow.verseIndex);
        if (verse == null) {
          Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the verseKey data(${Classroom.curr}-${verseShow.bookSerial}-${verseShow.chapterIndex}-${verseShow.verseIndex})"]));
          return;
        }
        var p = await Db().db.verseTodayPrgDao.one(verse.classroomId, verse.verseKeyId, TodayPrgType.justView.index);
        if (p == null) {
          Chapter? chapter = await Db().db.chapterDao.one(verse.classroomId, verse.bookSerial, verse.chapterIndex);
          if (chapter == null) {
            Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the chapter data(${verse.classroomId}-${verse.bookSerial}-${verse.chapterIndex})"]));
            return;
          }
          await Db().db.verseTodayPrgDao.insertOrFail(VerseTodayPrg(
                classroomId: verse.classroomId,
                bookSerial: verse.bookSerial,
                chapterKeyId: chapter.chapterKeyId,
                verseKeyId: verse.verseKeyId,
                time: 0,
                type: TodayPrgType.justView.index,
                sort: 0,
                progress: 0,
                viewTime: DateTime.now(),
                reviewCount: 0,
                reviewCreateDate: Date(0),
                finish: false,
              ));
          p = await Db().db.verseTodayPrgDao.one(verse.classroomId, verse.verseKeyId, TodayPrgType.justView.index);
          if (p == null) {
            Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant insert the verse(${verse.classroomId}-${verse.verseKeyId}-${TodayPrgType.justView})"]));
            return;
          }
        }
        var repeat = RepeatArgs(progresses: [p], repeatType: RepeatType.justView);
        await Nav.repeat.push(arguments: repeat);
        await Db().db.verseTodayPrgDao.delete(p.id!);
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
      onCardTapDown: (ChapterShow chapter) {
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
      onCardTapDown: (BookShow bookShow) {
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

  @override
  void onClose() {
    for (var view in viewList) {
      if (view != null) {
        view.dispose();
      }
    }
  }
}
