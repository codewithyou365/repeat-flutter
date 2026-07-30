import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/quick_entry/quick_entry.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'sc_state.dart';

class ScLogic extends GetxController {
  static const String id = "ScLogicId";
  final ScState state = ScState();
  static RegExp reg = RegExp(r'^[0-9a-zA-Z]+$');
  static const int nameMaxLength = 12;

  @override
  void onInit() async {
    super.onInit();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    state.list = await Db().db.classroomDao.getAllClassroom();
    update([ScLogic.id]);
  }

  void select(int classroomId, String classroomName) async {
    Classroom.curr = classroomId;
    Classroom.currName = classroomName;
    var quickEntry = await QuickEntry.get(classroomId);
    QuickEntry.pending = quickEntry;
    if (quickEntry != QuickEntryType.none) {
      QuickEntry.showGuiding();
    }
    Nav.scCr.push();
  }

  void add(String name) async {
    if (name.isEmpty) {
      Snackbar.show(I18nKey.labelClassroomNameEmpty.tr);
      return;
    }
    if (!reg.hasMatch(name)) {
      Snackbar.show(I18nKey.labelClassroomNameError.tr);
      return;
    }
    if (name.length > nameMaxLength) {
      Snackbar.show(I18nKey.labelNameTooLongWithArg.trArgs(['$nameMaxLength']));
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

  void rename(int classroomId, String name) async {
    if (name.isEmpty) {
      Snackbar.show(I18nKey.labelClassroomNameEmpty.tr);
      return;
    }
    if (!reg.hasMatch(name)) {
      Snackbar.show(I18nKey.labelClassroomNameError.tr);
      return;
    }
    if (name.length > nameMaxLength) {
      Snackbar.show(I18nKey.labelNameTooLongWithArg.trArgs(['$nameMaxLength']));
      return;
    }
    if (state.list.any((e) => e.id != classroomId && e.name == name)) {
      Snackbar.show(I18nKey.labelClassroomNameDuplicated.tr);
      return;
    }
    await Db().db.classroomDao.updateName(classroomId, name);
    var index = state.list.indexWhere((e) => e.id == classroomId);
    if (index != -1) {
      state.list[index] = Classroom(classroomId, name, state.list[index].sort, false);
    }
    update([ScLogic.id]);
    Get.back();
  }

  Future<void> _persistOrder() async {
    await Db().db.classroomDao.reorder(state.list.map((e) => e.id).toList());
    for (var i = 0; i < state.list.length; i++) {
      state.list[i].sort = i;
    }
    update([ScLogic.id]);
  }

  void moveToTop(int classroomId) async {
    var index = state.list.indexWhere((e) => e.id == classroomId);
    if (index <= 0) return;
    var item = state.list.removeAt(index);
    state.list.insert(0, item);
    await _persistOrder();
  }

  void moveToBottom(int classroomId) async {
    var index = state.list.indexWhere((e) => e.id == classroomId);
    if (index == -1 || index == state.list.length - 1) return;
    var item = state.list.removeAt(index);
    state.list.add(item);
    await _persistOrder();
  }

  void moveUp(int classroomId) async {
    var index = state.list.indexWhere((e) => e.id == classroomId);
    if (index <= 0) return;
    var item = state.list.removeAt(index);
    state.list.insert(index - 1, item);
    await _persistOrder();
  }

  void moveDown(int classroomId) async {
    var index = state.list.indexWhere((e) => e.id == classroomId);
    if (index == -1 || index == state.list.length - 1) return;
    var item = state.list.removeAt(index);
    state.list.insert(index + 1, item);
    await _persistOrder();
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
