import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/logic/schedule_help.dart';
import 'package:repeat_flutter/logic/widget/chapter_list.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/logic/widget/verse_list.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import '../../logic/doc_help.dart' show DocHelp;
import 'sc_cr_material_state.dart';

class ScCrMaterialLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final ScCrMaterialState state = ScCrMaterialState();
  late ChapterList chapterList = ChapterList<ScCrMaterialLogic>(this);
  late VerseList verseList = VerseList<ScCrMaterialLogic>(this);
  static RegExp reg = RegExp(r'^[0-9A-Z]+$');

  @override
  void onInit() {
    super.onInit();
    init();
  }

  init() async {
    state.list.clear();
    state.list.addAll(await Db().db.bookDao.getAll(Classroom.curr));
    update([ScCrMaterialLogic.id]);
  }

  resetDoc(int contentId) async {
    await Db().db.bookDao.updateDocId(contentId, 0);
    await init();
  }

  delete(int contentId, int bookSerial) async {
    showOverlay(() async {
      state.list.removeWhere((element) => identical(element.id, contentId));
      await Db().db.scheduleDao.hideContentAndDeleteVerse(contentId, bookSerial);
      Get.find<GsCrLogic>().init();
      update([ScCrMaterialLogic.id]);
    }, I18nKey.labelDeleting.tr);
  }

  showContent(int contentId) async {
    var content = await Db().db.bookDao.getById(contentId);
    if (content == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    await Nav.content.push(
      arguments: ContentArgs(
        bookName: content.name,
        removeWarning: () async {
          await init();
        },
      ),
    );
  }

  showChapter(int contentId) async {
    var content = await Db().db.bookDao.getById(contentId);
    if (content == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    chapterList.show(
      initContentNameSelect: content.name,
      removeWarning: () async {
        await init();
      },
    );
  }

  showVerse(int contentId) async {
    var content = await Db().db.bookDao.getById(contentId);
    if (content == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    verseList.show(
      initContentNameSelect: content.name,
      removeWarning: () async {
        await init();
      },
    );
  }

  addByZip(int contentId, int bookSerial) async {
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
      var zipTargetPath = rootPath.joinPath(DocPath.getRelativePath(bookSerial));
      await Zip.uncompress(File(path), zipTargetPath);
      ZipRootDoc? zipRoot = await ZipRootDoc.fromPath(zipTargetPath.joinPath(DocPath.zipRootFile));
      if (zipRoot == null) {
        Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['81']));
        return;
      }

      var kv = await DocHelp.fromPath(DocPath.getRelativeIndexPath(bookSerial));
      if (kv == null) {
        Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['88']));
        return;
      }
      var allDownloads = DocHelp.getDownloads(kv);
      // for media document
      for (var i = 0; i < allDownloads.length; i++) {
        var v = allDownloads[i];
        var relativeMediaPath = DocPath.getRelativePath(bookSerial).joinPath(v.path);
        var url = v.url;
        String hash = v.hash;
        await Db().db.docDao.insertDoc(Doc(url, relativeMediaPath, hash));
      }

      // for repeat document
      var indexPath = DocPath.getRelativeIndexPath(bookSerial);
      var targetRepeatDocPath = rootPath.joinPath(indexPath);
      String hash = await Hash.toSha1(targetRepeatDocPath);
      await Db().db.docDao.insertDoc(Doc(zipRoot.url, indexPath, hash));
      var indexJsonDocId = await Db().db.docDao.getIdByPath(indexPath);
      if (indexJsonDocId == null) {
        return;
      }

      await schedule(contentId, indexJsonDocId, zipRoot.url);
    }, I18nKey.labelImporting.tr);
  }

  add(String name) async {
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

  share(Book model) async {
    showTransparentOverlay(() async {
      var doc = await Db().db.docDao.getById(model.docId);
      if (doc == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSharing.tr);
        return;
      }
      var args = <dynamic>[model];
      Nav.gsCrContentShare.push(arguments: args);
    });
  }

  Future<int> getUnitCount(int bookSerial) async {
    RepeatDoc? kv = await DocHelp.fromPath(DocPath.getRelativeIndexPath(bookSerial));
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

  download(int contentId, int bookSerial, String url) async {
    state.indexCount.value = 0;
    state.indexTotal.value = 1;
    var indexPath = DocPath.getRelativeIndexPath(bookSerial);
    var success = await downloadDoc(
      url,
      indexPath,
      progressCallback: downloadProgress,
    );
    if (!success) {
      return;
    }
    RepeatDoc? kv = await DocHelp.fromPath(indexPath);
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
        DocPath.getRelativePath(bookSerial).joinPath(v.path),
        hash: v.hash,
        progressCallback: downloadProgress,
      );
    }
    var indexJsonDocId = await Db().db.docDao.getIdByPath(indexPath);
    if (indexJsonDocId == null) {
      return;
    }

    var ok = await schedule(contentId, indexJsonDocId, url);
    if (ok) {
      Nav.back();
    }
  }

  Future<bool> schedule(int contentId, int indexJsonDocId, String url) async {
    var result = await ScheduleHelp.addContentToSchedule(contentId, indexJsonDocId, url);
    if (!result) {
      return false;
    }
    Get.find<GsCrLogic>().init();
    init();
    return true;
  }
}
