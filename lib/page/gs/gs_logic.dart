import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_state.dart';

class GsLogic extends GetxController {
  static const String id = "GsLogicId";
  final GsState state = GsState();
  static RegExp reg = RegExp(r'^[0-9A-Z]+$');

  @override
  void onInit() async {
    super.onInit();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    state.list = await Db().db.classroomDao.getAllClassroom();
    update([GsLogic.id]);
  }

  select(int classroomId, String classroomName) {
    Classroom.curr = classroomId;
    Classroom.currName = classroomName;
    Nav.gsCr.push();
  }

  add(String name) async {
    if (name.isEmpty) {
      Get.back();
      Snackbar.show(I18nKey.labelClassroomNameEmpty.tr);
      return;
    }
    if (name.length > 3 || !reg.hasMatch(name)) {
      Get.back();
      Snackbar.show(I18nKey.labelClassroomNameError.tr);
      return;
    }
    if (state.list.any((e) => e.name == name)) {
      Get.back();
      Snackbar.show(I18nKey.labelClassroomNameDuplicated.tr);
      return;
    }
    var classroom = await Db().db.classroomDao.add(name);
    state.list.add(classroom);
    update([GsLogic.id]);
    Get.back();
  }

  delete(int classroomId, bool all) async {
    await Db().db.classroomDao.hide(classroomId);
    if (all) {
      await Db().db.scheduleDao.deleteByClassroomId(classroomId);
    }
    state.list.removeWhere((element) => element.id == classroomId);
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
