import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'sc_state.dart';

class ScLogic extends GetxController {
  static const String id = "ScLogicId";
  final ScState state = ScState();
  static RegExp reg = RegExp(r'^[0-9A-Z]+$');

  @override
  void onInit() async {
    super.onInit();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    state.list = await Db().db.classroomDao.getAllClassroom();
    update([ScLogic.id]);
  }

  select(int classroomId, String classroomName) {
    Classroom.curr = classroomId;
    Classroom.currName = classroomName;
    Nav.scCr.push();
  }

  add(String name) async {
    if (name.isEmpty) {
      Snackbar.show(I18nKey.labelClassroomNameEmpty.tr);
      return;
    }
    if (name.length > 3 || !reg.hasMatch(name)) {
      Snackbar.show(I18nKey.labelClassroomNameError.tr);
      return;
    }
    if (state.list.any((e) => e.name == name)) {
      Snackbar.show(I18nKey.labelClassroomNameDuplicated.tr);
      return;
    }
    var classroom = await Db().db.classroomDao.add(name);
    state.list.add(classroom);
    update([ScLogic.id]);
    Get.back();
  }

  Future<void> delete(int classroomId, bool all) async {
    if (all) {
      await Db().db.classroomDao.deleteAll(classroomId);
    } else {
      await Db().db.classroomDao.hide(classroomId);
    }
    state.list.removeWhere((element) => element.id == classroomId);
    update([ScLogic.id]);
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
