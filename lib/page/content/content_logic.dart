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
    var args = Get.arguments as List;
    String name = args[0];
    Future<void> Function() removeWarning = args[1];
    List<LessonShow> originalLessonShow = await LessonHelp.getLessons();
    lessonList = LessonList<ContentLogic>(
      parentLogic: this,
      removeWarning: removeWarning,
      //TODO
      segmentModified: () async {},
      initContentNameSelect: name,
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
