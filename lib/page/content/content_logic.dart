import 'package:get/get.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_book_list.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_lesson_list.dart';

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
    List<LessonShow> originalLessonShow = await LessonHelp.getLessons();
    List<VerseShow> originalVerseShow = await VerseHelp.getVerses();
    late ViewLogicLessonList<ContentLogic> lessonList;
    var verseList = ViewLogicVerseList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onLessonModified: () async {
        lessonList.originalBookShow = await BookHelp.getBooks();
        lessonList.originalLessonShow = await LessonHelp.getLessons();
        lessonList.collectData();
        lessonList.trySearch(force: true);
      },
      parentLogic: this,
      removeWarning: args.removeWarning,
      originalBookShow: originalBookShow,
      originalLessonShow: originalLessonShow,
      originalVerseShow: originalVerseShow,
      initContentNameSelect: args.bookName,
      initLessonSelect: args.initLessonSelect,
      selectVerseKeyId: args.selectVerseKeyId,
    );
    lessonList = ViewLogicLessonList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onLessonModified: () async {
        verseList.originalBookShow = await BookHelp.getBooks();
        verseList.originalLessonShow = await LessonHelp.getLessons();
        verseList.originalVerseShow = await VerseHelp.getVerses();
        verseList.collectData();
        verseList.trySearch(force: true);
      },
      parentLogic: this,
      removeWarning: args.removeWarning,
      initContentNameSelect: args.bookName,
      initLessonSelect: args.initLessonSelect,
      originalBookShow: originalBookShow,
      originalLessonShow: originalLessonShow,
    );
    var bookList = ViewLogicBookList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      parentLogic: this,
      initContentNameSelect: args.bookName,
      originalBookShow: originalBookShow,
    );
    viewList[0] = bookList;
    viewList[1] = lessonList;
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
