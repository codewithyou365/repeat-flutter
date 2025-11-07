import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/logic/import_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'sc_cr_material_state.dart';

class ScCrMaterialLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final ScCrMaterialState state = ScCrMaterialState();
  static RegExp reg = RegExp(r'^[0-9A-Z]+$');
  final SubList<int> sub = [];

  @override
  void onInit() {
    super.onInit();
    sub.on([EventTopic.deleteBook], delete);
    init();
  }

  @override
  void onClose() {
    super.onClose();
    sub.off();
  }

  Future<void> init() async {
    state.list.clear();
    var books = await Db().db.bookDao.getAll(Classroom.curr);
    state.list.addAll(books);
    update([ScCrMaterialLogic.id]);
  }

  void delete(int? bookId) {
    if (bookId != null) {
      state.list.removeWhere((element) => identical(element.id, bookId));
      update([ScCrMaterialLogic.id]);
    }
  }

  Future<void> showContent({
    required int bookId,
    int defaultTap = 0,
  }) async {
    var content = await Db().db.bookDao.getById(bookId);
    if (content == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    await Nav.content.push(
      arguments: ContentArgs(
        bookName: content.name,
        enableEnteringRepeatView: true,
      ),
    );
  }

  Future<void> addByZip(int bookId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    var path = "";
    if (result != null && result.files.single.path != null) {
      path = result.files.single.path!;
    } else {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return;
    }
    showOverlay(() async {
      var rootPath = await DocPath.getContentPath();
      var zipTargetPath = rootPath.joinPath(DocPath.getRelativePath(bookId));
      await Zip.uncompress(File(path), zipTargetPath);
      ZipRootDoc? zipRoot = await ZipRootDoc.fromPath(zipTargetPath.joinPath(DocPath.zipRootFile));
      if (zipRoot == null) {
        Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['81']));
        return;
      }

      var kv = await DocHelp.fromPath(DocPath.getRelativeIndexPath(bookId));
      if (kv == null) {
        Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['88']));
        return;
      }
      await schedule(bookId, zipRoot.url);
    }, I18nKey.labelImporting.tr);
  }

  Future<void> add(String name) async {
    if (name.isEmpty) {
      Get.back();
      Snackbar.show(I18nKey.labelBookNameEmpty.tr);
      return;
    }
    if (name.length > 3 || !reg.hasMatch(name)) {
      Get.back();
      Snackbar.show(I18nKey.labelBookNameError.tr);
      return;
    }
    if (state.list.any((e) => e.name == name)) {
      Get.back();
      Snackbar.show(I18nKey.labelBookNameDuplicated.tr);
      return;
    }
    await Db().db.bookDao.add(name);
    await init();
    Get.back();
  }

  Future<void> share(Book model) async {
    showTransparentOverlay(() async {
      var args = <dynamic>[model];
      Nav.scCrMaterialShare.push(arguments: args);
    });
  }

  Future<int> getUnitCount(int bookSerial) async {
    BookContent? kv = await DocHelp.fromPath(DocPath.getRelativeIndexPath(bookSerial));
    if (kv == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return 0;
    }
    var total = 0;
    for (var d in kv.chapter) {
      total += d.verse.length;
    }
    return total;
  }

  void downloadProgress(int startTime, int count, int total, bool finish) {
    if (finish) {
      state.indexCount.value++;
      state.contentProgress.value = 1;
    } else {
      if (total == -1) {
        int elapse = DateTime.now().millisecondsSinceEpoch - startTime;
        int predict = 5 * 60 * 1000;
        double progress = elapse / predict;
        if (progress > 0.9) {
          state.contentProgress.value = 0.9;
        } else {
          state.contentProgress.value = progress;
        }
      } else {
        state.contentProgress.value = count / total;
      }
    }
  }

  void download(int bookId, String url) async {
    state.indexCount.value = 0;
    state.indexTotal.value = 1;
    final rawUrl = url;
    List<String> urlAndCredentials = url.split("#");
    String credentials = '';
    if (urlAndCredentials.length == 2) {
      url = urlAndCredentials[0];
      credentials = urlAndCredentials[1];
      credentials = 'Basic ${base64.encode(utf8.encode(credentials))}';
    }
    var indexPath = DocPath.getRelativeIndexPath(bookId);
    var downloadDocResult = await DownloadDoc.start(
      url,
      indexPath,
      credentials: credentials,
      progressCallback: downloadProgress,
      skipSsl: true,
    );
    if (downloadDocResult != DownloadDocResult.success) {
      return;
    }
    BookContent? kv = await DocHelp.fromPath(indexPath);
    if (kv == null) {
      return;
    }
    var rootUrl = url.substring(0, url.lastIndexOf("/"));
    var allDownloads = DocHelp.getDownloads(kv, rootUrl: rootUrl);

    state.indexTotal.value = state.indexTotal.value + kv.chapter.length;
    for (int i = 0; i < allDownloads.length; i++) {
      var v = allDownloads[i];
      var downloadDocResult = await DownloadDoc.start(
        v.url,
        credentials: credentials,
        DocPath.getRelativePath(bookId).joinPath(v.path),
        hash: v.hash,
        progressCallback: downloadProgress,
        skipSsl: true,
      );
      if (downloadDocResult != DownloadDocResult.success) {
        return;
      }
    }

    var ok = await schedule(bookId, url);
    if (ok) {
      Nav.back();
    }
  }

  Future<bool> schedule(int bookId, String url) async {
    var result = await ImportHelp.import(bookId, url);
    if (!result) {
      return false;
    }
    init();
    return true;
  }

  void importBook(Book book) async {
    int? index = await Select.showSheet(
      title: I18nKey.selectImportType.tr,
      keys: [
        I18nKey.labelRemoteImport.tr,
        I18nKey.labelLocalZipImport.tr,
      ],
    );
    if (index == null) {
      return;
    }
    if (index == 0) {
      openDownloadDialog(book);
    } else {
      addByZip(book.id!);
    }
  }

  void openDownloadDialog(Book model) {
    final state = this.state;
    RxString downloadUrl = model.url.obs;
    MsgBox.strInputWithYesOrNo(
      downloadUrl,
      I18nKey.labelDownloadBook.tr,
      I18nKey.labelRemoteUrl.tr,
      nextChildren: [
        Obx(() {
          return LinearProgressIndicator(
            value: state.indexCount.value / state.indexTotal.value,
            semanticsLabel: "${(state.indexCount.value / state.indexTotal.value * 100).toStringAsFixed(1)}%",
          );
        }),
        const SizedBox(height: 20),
        Obx(() {
          return LinearProgressIndicator(
            value: state.contentProgress.value,
            semanticsLabel: "${(state.contentProgress.value * 100).toStringAsFixed(1)}%",
          );
        }),
        const SizedBox(height: 10),
      ],
      yes: () {
        download(model.id!, downloadUrl.value);
      },
      yesBtnTitle: I18nKey.btnDownload.tr,
      noBtnTitle: I18nKey.btnClose.tr,
      qrPagePath: Nav.scan.path,
    );
  }

  void createBook(int bookId) async {
    List<String> keys = RepeatViewEnum.values.map((e) => e.name.toUpperCase()).toList();
    int? index = await Select.showSheet(title: I18nKey.selectBookType.tr, keys: keys);
    if (index == null) {
      return;
    }
    String content = keys[index].toLowerCase();
    showTransparentOverlay(() async {
      var rootPath = await DocPath.getContentPath();
      var relativePath = DocPath.getRelativePath(bookId);
      var workPath = rootPath.joinPath(relativePath);
      await Folder.ensureExists(workPath);
      await Db().db.bookDao.create(bookId, '{"s":"$content"}');
      init();
    });
  }
}
