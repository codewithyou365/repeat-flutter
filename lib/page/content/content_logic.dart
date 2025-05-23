import 'package:get/get.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
import 'package:repeat_flutter/page/content/logic/lesson_list.dart';

import 'content_state.dart';

class ContentLogic extends GetxController {
  static const String id = "ContentLogicId";
  final ContentState state = ContentState();

  LessonList? lessonList;

  @override
  void onInit() async {
    super.onInit();
    List<LessonShow> originalLessonShow = await LessonHelp.getLessons();
    lessonList = LessonList<ContentLogic>(
      parentLogic: this,
      removeWarning: () async {},
      //TODO
      segmentModified: () async {},
      //TODO
      originalLessonShow: originalLessonShow,
    );
    update([ContentLogic.id]);
  }

  @override
  void onClose() {
    state.searchController.dispose();
    state.focusNode.dispose();
  }
}
