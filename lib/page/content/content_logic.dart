import 'package:get/get.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_book_list.dart';
import 'package:repeat_flutter/page/content/logic/view_logic_lesson_list.dart';

import 'content_state.dart';
import 'logic/view_logic.dart';
import 'logic/view_logic_segment_list.dart';

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
    List<SegmentShow> originalSegmentShow = await SegmentHelp.getSegments();
    viewList[0] = ViewLogicBookList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      parentLogic: this,
      initContentNameSelect: args.bookName,
      originalBookShow: originalBookShow,
    );
    var segmentList = ViewLogicSegmentList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      parentLogic: this,
      removeWarning: args.removeWarning,
      originalLessonShow: originalLessonShow,
      originalSegmentShow: originalSegmentShow,
      initContentNameSelect: args.bookName,
      initLessonSelect: args.initLessonSelect,
      selectSegmentKeyId: args.selectSegmentKeyId,
    );
    viewList[1] = ViewLogicLessonList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      onLessonModified: () async {
        segmentList.originalLessonShow = await LessonHelp.getLessons();
        segmentList.collectData();
      },
      parentLogic: this,
      removeWarning: args.removeWarning,
      segmentModified: () async {},
      initContentNameSelect: args.bookName,
      initLessonSelect: args.initLessonSelect,
      originalLessonShow: originalLessonShow,
    );
    viewList[2] = segmentList;
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
