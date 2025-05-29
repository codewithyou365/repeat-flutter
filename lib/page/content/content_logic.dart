import 'package:get/get.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
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
    var args = Get.arguments as List;
    String name = args[0];
    Future<void> Function() removeWarning = args[1];
    List<BookShow> originalBookShow = await BookHelp.getBooks();
    List<LessonShow> originalLessonShow = await LessonHelp.getLessons();
    List<SegmentShow> originalSegmentShow = await SegmentHelp.getSegments();
    viewList[0] = ViewLogicBookList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      parentLogic: this,
      initContentNameSelect: name,
      originalBookShow: originalBookShow,
    );
    viewList[1] = ViewLogicLessonList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      parentLogic: this,
      removeWarning: removeWarning,
      //TODO
      segmentModified: () async {},
      initContentNameSelect: name,
      originalLessonShow: originalLessonShow,
    );
    viewList[2] = ViewLogicSegmentList<ContentLogic>(
      onSearchUnfocus: () {
        state.startSearch.value = false;
      },
      parentLogic: this,
      removeWarning: removeWarning,
      originalSegmentShow: originalSegmentShow,
    );
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
