import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/logic/schedule_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import '../../logic/doc_help.dart' show DocHelp;
import 'sc_cr_material_state.dart';

class ScCrMaterialLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final ScCrMaterialState state = ScCrMaterialState();
  static RegExp reg = RegExp(r'^[0-9A-Z]+$');

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    state.list.clear();
    state.list.addAll(await Db().db.bookDao.getAll(Classroom.curr));
    update([ScCrMaterialLogic.id]);
  }

  Future<void> resetDoc(int bookId) async {
    await Db().db.bookDao.updateDocId(bookId, 0);
    await init();
  }

  Future<void> delete(int bookId) async {
    showOverlay(() async {
      state.list.removeWhere((element) => identical(element.id, bookId));
      await Db().db.scheduleDao.hideContentAndDeleteVerse(bookId);
      Get.find<GsCrLogic>().init();
      update([ScCrMaterialLogic.id]);
    }, I18nKey.labelDeleting.tr);
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
        removeWarning: () async {
          await init();
        },
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
      Nav.gsCrContentShare.push(arguments: args);
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

  downloadProgress(int startTime, int count, int total, bool finish) {
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

  download(int bookId, String url) async {
    state.indexCount.value = 0;
    state.indexTotal.value = 1;
    var indexPath = DocPath.getRelativeIndexPath(bookId);
    var success = await downloadDoc(
      url,
      indexPath,
      progressCallback: downloadProgress,
    );
    if (!success) {
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
      await downloadDoc(
        v.url,
        DocPath.getRelativePath(bookId).joinPath(v.path),
        hash: v.hash,
        progressCallback: downloadProgress,
      );
    }

    var ok = await schedule(bookId, url);
    if (ok) {
      Nav.back();
    }
  }

  Future<bool> schedule(int bookId, String url) async {
    var result = await ScheduleHelp.addBookToSchedule(bookId, url);
    if (!result) {
      return false;
    }
    Get.find<GsCrLogic>().init();
    init();
    return true;
  }

  void createBook(int bookId) async {
    String content = await Nav.gsCrContentTemplate.push(arguments: <int>[bookId]);
    showOverlay(() async {
      var rootPath = await DocPath.getContentPath();
      var relativePath = DocPath.getRelativePath(bookId);
      var workPath = rootPath.joinPath(relativePath);
      await Folder.ensureExists(workPath);
      await Db().db.bookDao.create(bookId, '{"s":"$content"}');
      Get.find<GsCrLogic>().init();
      init();
    }, I18nKey.labelSaving.tr);
  }
}
