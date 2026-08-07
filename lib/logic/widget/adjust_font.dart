import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/classroom_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class AdjustFont<T extends GetxController> {
  final T parentLogic;

  AdjustFont(this.parentLogic);

  /// [bookId] 为 null 就是课堂级（提示的字体）：[map] 是 Classroom.content，
  /// 字体文件落在课堂自己的资源目录里，落库走 ClassroomDao。
  /// 传了 bookId 就是书本级（'q'/'a'/'n' 的字体）：[map] 是 Book.content。
  Future<void> open({
    required int? bookId,
    required String fontPrefix,
    required Map<String, dynamic> map,
  }) async {
    List<DownloadContent> list = DownloadContent.toList(map['d']) ?? [];
    String alias = VerseField.getStr(map, fontPrefix, VerseField.fontAlias) ?? '';
    final fontSizeVal = RxDouble(textFontSize(fontPrefix, map));
    RxString fontDisplay = RxString(alias);
    return Sheet.showBottomSheet<void>(
      Get.context!,
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(I18nKey.adjustFont.tr),
          RowWidget.buildDivider(),
        ],
      ),
      Column(
        children: [
          Obx(() {
            return RowWidget.buildSelect(
              title: "${I18nKey.fontSize.tr} (${fontSizeVal.value})",
              onTap: () async {
                final size = await fontSize(bookId, fontPrefix, map);
                if (size != 0) {
                  fontSizeVal.value = size;
                }
              },
            );
          }),
          RowWidget.buildDividerWithoutColor(),
          Obx(() {
            return RowWidget.buildTextWithEdit(
              I18nKey.font.tr,
              fontDisplay,
              onTap: () async {
                final allowedExtensions = ["ttf", "otf"];
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: allowedExtensions,
                );
                var download = await _copyToDocDir(
                  bookId: bookId,
                  result: result,
                  allowedExtensions: allowedExtensions,
                );
                if (result == null || download == null) {
                  return;
                }
                int existingIndex = list.indexWhere((e) => e.hash == download.hash);
                if (existingIndex != -1) {
                  list[existingIndex] = download;
                } else {
                  list.add(download);
                }

                String fileName = result.files.single.name;

                var rootPath = await DocPath.getContentPath();
                final localFolder = rootPath.joinPath(_relativeFolder(bookId).joinPath(download.folder));
                final filePath = localFolder.joinPath(download.name);

                var ok = await ClassroomHelp.registerCustomFont(fileName, filePath);
                if (!ok) {
                  Snackbar.show(I18nKey.importFontFail.tr);
                  return;
                }

                map['d'] = list.map((e) => e.toJson()).toList();
                VerseField.setStr(map, fontPrefix, VerseField.fontAlias, fileName);
                VerseField.setStr(map, fontPrefix, VerseField.fontHash, download.hash);
                await _save(bookId, map);

                fontDisplay.value = fileName;

                parentLogic.update(["RepeatLogic"]);
              },
              extra: fontDisplay.value.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () async {
                        VerseField.setStr(map, fontPrefix, VerseField.fontAlias, null);
                        VerseField.setStr(map, fontPrefix, VerseField.fontHash, null);
                        // 清空后这一块可能空了，被 setStr 从数组末尾截掉——补回占位块，
                        // 不然这一条提示会连着 tab 一起消失。
                        _keepTipSlot(fontPrefix, map);

                        fontDisplay.value = "";

                        await _save(bookId, map);

                        parentLogic.update(["RepeatLogic"]);
                      },
                      icon: const Icon(Icons.cleaning_services_sharp),
                    ),
            );
          }),
        ],
      ),
      height: RowWidget.rowHeight * 3 + RowWidget.dividerHeight * 2,
    );
  }

  double textFontSize(String fontPrefix, Map<String, dynamic> map) {
    final v = VerseField.getStr(map, fontPrefix, VerseField.fontSize);
    if (v != null) {
      return double.parse(v);
    }
    return 17;
  }

  Future<double> fontSize(int? bookId, String fontPrefix, Map<String, dynamic> map) async {
    double ret = 0;
    RxDouble v = RxDouble(textFontSize(fontPrefix, map));
    await MsgBox.myDialog(
      title: I18nKey.edit.tr,
      content: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text(
              '${I18nKey.fontSize.tr}: ${v.value.round()}',
              style: TextStyle(fontSize: v.value),
            ),
            Slider(
              value: v.value,
              min: 10,
              max: 40,
              divisions: 30,
              label: '${v.value.round()}',
              onChanged: (newVal) {
                v.value = newVal;
              },
            ),
          ],
        ),
      ),
      action: MsgBox.buttonsWithDivider(
        buttons: [
          MsgBox.button(
            text: I18nKey.btnCancel.tr,
            onPressed: () {
              Get.back();
            },
          ),
          MsgBox.button(
            text: I18nKey.save.tr,
            onPressed: () async {
              VerseField.setStr(map, fontPrefix, VerseField.fontSize, '${v.value}');
              await _save(bookId, map);
              Get.back();
              ret = v.value;
              parentLogic.update(["RepeatLogic"]);
            },
          ),
        ],
      ),
    );
    return ret;
  }

  /// 内容落哪一层：课堂级（[bookId] 为 null）走 ClassroomDao，书本级走 BookDao。
  Future<void> _save(int? bookId, Map<String, dynamic> map) async {
    if (bookId == null) {
      await Db().db.classroomDao.updateContent(Classroom.curr, jsonEncode(map));
      return;
    }
    await Db().db.bookDao.updateBookContent(bookId, jsonEncode(map));
  }

  /// 字体文件落哪个目录：课堂级跟游戏一样落在课堂自己的资源目录下。
  String _relativeFolder(int? bookId) {
    return bookId == null //
        ? DocPath.getClassroomResRelativePath(Classroom.curr)
        : DocPath.getRelativePath(bookId);
  }

  /// 提示那一条的字段块被清空后补个占位块回来：下标就是提示的身份，
  /// 末尾的空块被截掉会让这一条提示整体消失。
  void _keepTipSlot(String fontPrefix, Map<String, dynamic> map) {
    if (VerseField.baseOf(fontPrefix) != 't') {
      return;
    }
    VerseField.ensureTipCount(map, VerseField.indexOf(fontPrefix) + 1);
  }

  /// [DocHelp.tryCopyToDocDir] 的课堂级版本：校验扩展名之后把文件复制到
  /// 课堂资源目录（书本级仍旧交给 DocHelp）。
  Future<DownloadContent?> _copyToDocDir({
    required int? bookId,
    required FilePickerResult? result,
    required List<String> allowedExtensions,
  }) async {
    if (bookId != null) {
      return await DocHelp.tryCopyToDocDir(
        bookId: bookId,
        result: result,
        allowedExtensions: allowedExtensions,
      );
    }
    final pickedPath = result?.files.single.path;
    if (result == null || pickedPath == null) {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return null;
    }
    try {
      final extension = result.files.single.name.split('.').last;
      if (!allowedExtensions.containsIgnoreCase(extension)) {
        Snackbar.show(I18nKey.labelFileExtensionNotMatch.trArgs([jsonEncode(allowedExtensions)]));
        return null;
      }
      final hash = await Hash.toSha1(pickedPath);
      final download = DownloadContent(url: ".$extension", hash: hash);

      final rootPath = await DocPath.getContentPath();
      final localFolder = rootPath.joinPath(_relativeFolder(null).joinPath(download.folder));
      await Folder.ensureExists(localFolder);
      await File(pickedPath).copy(localFolder.joinPath(download.name));
      return download;
    } catch (e) {
      Snackbar.show(e.toString());
      return null;
    }
  }
}
