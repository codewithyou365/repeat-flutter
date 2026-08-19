import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/classroom_import_help.dart';
import 'package:repeat_flutter/logic/widget/quick_entry/quick_entry.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/select/select.dart';
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

  /// 悬浮按钮统一入口：新增课堂 / 远程导入 / 本地ZIP导入。
  /// 远程和本地导入都是新建一个课堂，不会动已有课堂。
  void openAddOrImportMenu() async {
    int? index = await Select.showSheet(
      title: I18nKey.labelAddOrImportClassroom.tr,
      keys: [
        I18nKey.btnAdd.tr,
        I18nKey.labelRemoteImport.tr,
        I18nKey.labelLocalZipImport.tr,
      ],
      leadings: const [
        Icon(Icons.add),
        Icon(Icons.cloud_download),
        Icon(Icons.folder_zip),
      ],
    );
    if (index == null) {
      return;
    }
    switch (index) {
      case 0:
        _openAddDialog();
        break;
      case 1:
        _importFromUrl();
        break;
      default:
        _importFromZip();
        break;
    }
  }

  void _openAddDialog() {
    RxString classroomName = "".obs;
    MsgBox.strInputWithYesOrNo(
      classroomName,
      I18nKey.btnAdd.tr,
      I18nKey.labelClassroomName.tr,
      yes: () {
        add(classroomName.value);
      },
    );
  }

  void _importFromUrl() {
    RxString downloadUrl = "".obs;
    MsgBox.strInputWithYesOrNo(
      downloadUrl,
      I18nKey.classroomImport.tr,
      I18nKey.labelRemoteUrl.tr,
      nextChildren: [
        Obx(() {
          return LinearProgressIndicator(
            value: state.importProgress.value,
            semanticsLabel: "${(state.importProgress.value * 100).toStringAsFixed(1)}%",
          );
        }),
        const SizedBox(height: 10),
      ],
      yes: () async {
        var url = downloadUrl.value;
        if (url.isEmpty) {
          Snackbar.show(I18nKey.labelDataAnomaly.trArgs(['url']));
          return;
        }
        // 和单本远程导入一个格式：url#user:pass
        String credentials = '';
        final urlAndCredentials = url.split("#");
        if (urlAndCredentials.length == 2) {
          url = urlAndCredentials[0];
          credentials = 'Basic ${base64.encode(utf8.encode(urlAndCredentials[1]))}';
        }
        // 远程文档里没有课堂名，先按 URL 起个名，导入后用户可以自己改名
        var ok = await _doImport(
          () => ClassroomImportHelp.fromUrl(
            url: url,
            classroomName: _nameFromUrl(url),
            credentials: credentials,
            onProgress: _onImportProgress,
          ),
          // 进度条就在这个对话框里，别再盖一层遮罩
          overlay: false,
        );
        if (ok) {
          Nav.back();
        }
      },
      yesBtnTitle: I18nKey.btnDownload.tr,
      noBtnTitle: I18nKey.close.tr,
      qrPagePath: Nav.scan.path,
    );
  }

  void _importFromZip() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return;
    }
    final path = result.files.single.path!;
    String? password;
    if (await Zip.isEncrypted(File(path))) {
      password = await MsgBox.password(I18nKey.labelZipPasswordRequired.tr, I18nKey.labelZipPassword.tr);
      if (password == null) {
        Snackbar.show(I18nKey.labelLocalImportCancel.tr);
        return;
      }
    }
    // 导出时 zip 就叫 <课堂名>.zip，这里原样当课堂名用（会被清洗和去重）
    final name = result.files.single.name.replaceAll(RegExp(r'\.zip$'), '');
    await _doImport(
      () => ClassroomImportHelp.fromZip(
        zipPath: path,
        classroomName: name,
        password: password,
        onProgress: _onImportProgress,
      ),
    );
  }

  /// https://1.2.3.4:4324/index.json -> 'classroom'（清洗和去重交给 addWithUniqueName）
  static String _nameFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? [];
    for (final s in segments.reversed) {
      final name = s.split('.').first;
      if (name.isNotEmpty && name != 'index') {
        return name;
      }
    }
    return 'classroom';
  }

  void _onImportProgress(int done, int total) {
    state.importProgress.value = total == 0 ? 0 : done / total;
  }

  /// [overlay] 为假表示外面已经有对话框在显示进度了（远程导入），别再盖一层遮罩
  Future<bool> _doImport(Future<ClassroomImportResult?> Function() run, {bool overlay = true}) async {
    state.importProgress.value = 0;
    Future<bool> doIt() async {
      final result = await run();
      if (result == null) {
        return false;
      }
      state.list = await Db().db.classroomDao.getAllClassroom();
      update([ScLogic.id]);
      Snackbar.show(I18nKey.labelClassroomImportSuccess.trArgs([result.classroom.name, '${result.bookCount}']));
      return true;
    }

    if (!overlay) {
      return await doIt();
    }
    var ok = false;
    await showOverlay(() async {
      ok = await doIt();
    }, I18nKey.labelClassroomImporting.tr);
    return ok;
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
      var old = state.list[index];
      state.list[index] = Classroom(classroomId, name, old.sort, false, old.content, old.contentVersion);
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
