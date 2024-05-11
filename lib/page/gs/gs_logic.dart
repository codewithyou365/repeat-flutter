import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'gs_state.dart';

class GsLogic extends GetxController {
  static const String id = "GsLogicId";
  final GsState state = GsState();
  static RegExp reg = RegExp(r'^[0-9a-zA-Z]+$');

  @override
  void onInit() async {
    super.onInit();
    state.list = await Db().db.classroomDao.getAllClassroom();
    update([GsLogic.id]);
  }

  add(String name) async {
    if (name.isEmpty) {
      Get.snackbar(
        I18nKey.labelTips.tr,
        I18nKey.labelClassroomNameEmpty.tr,
      );
      return;
    }
    if (name.length > 3 || !reg.hasMatch(name)) {
      Get.snackbar(
        I18nKey.labelTips.tr,
        I18nKey.labelClassroomNameError.tr,
      );
      return;
    }
    var classroom = await Db().db.classroomDao.add(name);
    state.list.add(classroom);
    update([GsLogic.id]);
    Get.back();
  }

  delete(String name) async {
    await Db().db.classroomDao.deleteContentIndex(Classroom(name, "", 0));
    state.list.removeWhere((element) => element.name == name);
    update([GsLogic.id]);
  }
}

class ClassroomView {
  String backgroundColor;
  String textColor;
  String title;
  String description;

  ClassroomView(this.backgroundColor, this.textColor, this.title, this.description);

  factory ClassroomView.fromJson(Map<String, dynamic> json) {
    return ClassroomView(
      json['backgroundColor'],
      json['textColor'],
      json['title'],
      json['description'],
    );
  }
}
