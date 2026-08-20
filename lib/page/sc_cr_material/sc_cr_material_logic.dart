import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';
import 'package:repeat_flutter/logic/ai/ai_support.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
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
  static RegExp reg = RegExp(r'^[0-9a-zA-Z]+$');
  static const int nameMaxLength = 12;
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
        bookId: bookId,
        enableEnteringRepeatView: true,
      ),
    );
  }

  void showMediaList() {
    Nav.mediaList.push();
  }

  void showSearch() {
    Nav.scCrMaterialSearch.push();
  }

  void showAdvancedEdit() {
    Nav.scCrMaterialEdit.push();
  }

  void showGameList() {
    Nav.gameList.push();
  }

  Future<void> add(String name) async {
    if (name.isEmpty) {
      Get.back();
      Snackbar.show(I18nKey.labelBookNameEmpty.tr);
      return;
    }
    if (!reg.hasMatch(name)) {
      Get.back();
      Snackbar.show(I18nKey.labelBookNameError.tr);
      return;
    }
    if (name.length > nameMaxLength) {
      Get.back();
      Snackbar.show(I18nKey.labelNameTooLongWithArg.trArgs(['$nameMaxLength']));
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

  void addChapter(Book book) async {
    // 平台不支持端上模型时不弹这个二选一：只有一条路可走，多一次点击没有意义。
    if (!AiSupport.available) {
      Nav.scCrMaterialAddChapter.push(arguments: [book]);
      return;
    }
    int? index = await Select.showSheet(
      title: I18nKey.labelAddChapter.tr,
      keys: [I18nKey.aiChapterFromMedia.tr, I18nKey.aiChapterFromRecord.tr],
      leadings: const [Icon(Icons.subtitles), Icon(Icons.mic)],
    );
    if (index == null) {
      return;
    }
    if (index == 0) {
      Nav.scCrMaterialAddChapter.push(arguments: [book]);
      return;
    }
    await _addChapterByRecord(book);
  }

  /// 息屏录音建章。开录之前先确认四个角色的模型都齐了——不齐就引导去下载，
  /// 而不是让用户录完一整段才发现合成不出声音。
  Future<void> _addChapterByRecord(Book book) async {
    final catalog = await AiCatalog.load();
    final missing = await AiModelHelp.missingRoles(catalog);
    if (missing.isNotEmpty) {
      MsgBox.yesOrNo(
        title: I18nKey.aiChapterFromRecord.tr,
        desc: I18nKey.aiModelMissing.trArgs([missing.map((e) => e.label).join('、')]),
        yesBtnTitle: I18nKey.aiGoDownload.tr,
        yes: () {
          Get.back();
          Nav.scSettingsAi.push();
        },
        no: () => Get.back(),
      );
      return;
    }
    Nav.scCrMaterialRecord.push(arguments: [book]);
  }

  void createBook(int bookId) async {
    List<String> keys = RepeatViewEnum.values.map((e) => e.name.toUpperCase()).toList();
    int? index = await Select.showSheet(title: I18nKey.selectBookType.tr, keys: keys);
    if (index == null) {
      return;
    }
    String content = keys[index].toLowerCase();
    showTransparentOverlay(() async {
      // 媒体文件统一落在课堂的 f 目录，书本自己没有目录，这里不用再建
      await Db().db.bookDao.create(bookId, '{"s":"$content"}');
      init();
    });
  }
}
