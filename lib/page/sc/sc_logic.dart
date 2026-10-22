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
    await _reload();
  }

  /// 重新读课堂列表，顺便算出哪些课堂还是空的（一本书都没有，界面上标红）
  Future<void> _reload() async {
    final list = await Db().db.classroomDao.getAllClassroom();
    final Set<int> emptyIds = {};
    for (final c in list) {
      if ((await Db().db.bookDao.getAll(c.id)).isEmpty) {
        emptyIds.add(c.id);
      }
    }
    state.list = list;
    state.emptyIds = emptyIds;
    update([ScLogic.id]);
  }

  /// 点课堂：空课堂先问是导入还是直接进去手动建书，有书的直接进
  void tap(Classroom classroom) async {
    if (!state.emptyIds.contains(classroom.id)) {
      select(classroom.id, classroom.name);
      return;
    }
    int? index = await Select.showSheet(
      title: I18nKey.classroomImport.tr,
      keys: [
        I18nKey.labelRemoteImport.tr,
        I18nKey.labelLocalZipImport.tr,
        I18nKey.labelEnterClassroomDirectly.tr,
      ],
      leadings: const [
        Icon(Icons.cloud_download),
        Icon(Icons.folder_zip),
        Icon(Icons.login),
      ],
    );
    switch (index) {
      case 0:
        _importFromUrl(classroom.id);
        break;
      case 1:
        _importFromZip(classroom.id);
        break;
      case 2:
        select(classroom.id, classroom.name);
        break;
    }
  }

  void select(int classroomId, String classroomName) async {
    Classroom.curr = classroomId;
    Classroom.currName = classroomName;
    var quickEntry = await QuickEntry.get(classroomId);
    QuickEntry.pending = quickEntry;
    if (quickEntry != QuickEntryType.none) {
      QuickEntry.showGuiding();
    }
    await Nav.scCr.push();
    // 进去可能手动加了书，回来重新算一下哪些课堂还是空的
    await _reload();
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
    await Db().db.classroomDao.add(name);
    // add 撞上同名的隐藏课堂会把它恢复出来，那个课堂未必是空的，所以整体重读
    await _reload();
    Get.back();
  }

  /// 悬浮按钮：先建一个空课堂，导入内容是之后点这个（标红的）课堂再做的
  void openAddDialog() {
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

  void _importFromUrl(int classroomId) {
    RxString downloadUrl = "".obs;
    // 上次导入留下的进度别带进新对话框
    state.importProgress.value = 0;
    state.downloadProgress.value = 0;
    MsgBox.strInputWithYesOrNo(
      downloadUrl,
      I18nKey.classroomImport.tr,
      I18nKey.labelRemoteUrl.tr,
      nextChildren: [
        Obx(() {
          return Column(
            children: [
              LinearProgressIndicator(
                value: state.importProgress.value,
                semanticsLabel: "${(state.importProgress.value * 100).toStringAsFixed(1)}%",
              ),
              // 下载 index.json 和媒体文件时书本进度还没动，单独给一条当前文件的下载进度
              const SizedBox(height: 4),
              LinearProgressIndicator(value: state.downloadProgress.value),
            ],
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
        // 全程盖全局遮罩：导入期间什么都点不了，避免重复点下载起两个导入互相干扰
        var ok = await _doImport(
          () => ClassroomImportHelp.fromUrl(
            url: url,
            classroomId: classroomId,
            credentials: credentials,
            onProgress: _onImportProgress,
            downloadProgress: _onDownloadProgress,
          ),
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

  void _importFromZip(int classroomId) async {
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
    await _doImport(
      () => ClassroomImportHelp.fromZip(
        zipPath: path,
        classroomId: classroomId,
        password: password,
        onProgress: _onImportProgress,
      ),
    );
  }

  void _onImportProgress(int done, int total) {
    state.importProgress.value = total == 0 ? 0 : done / total;
  }

  void _onDownloadProgress(int startTime, int count, int total, bool finish) {
    // chunked 响应（比如课堂 index.json）拿不到总大小，total 是 -1
    state.downloadProgress.value = total > 0 ? count / total : null;
  }

  Future<bool> _doImport(Future<ClassroomImportResult?> Function() run) async {
    state.importProgress.value = 0;
    state.downloadProgress.value = 0;
    Future<bool> doIt() async {
      final result = await run();
      if (result == null) {
        return false;
      }
      await _reload();
      Snackbar.show(I18nKey.labelClassroomImportSuccess.trArgs([result.classroom.name, '${result.bookCount}']));
      return true;
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
