import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/font_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class AdjustFont<T extends GetxController> {
  final T parentLogic;

  AdjustFont(this.parentLogic);

  Future<void> open({
    required int bookId,
    required String fontPrefix,
    required Map<String, dynamic> bookMap,
  }) async {
    List<DownloadContent> list = DownloadContent.toList(bookMap['d']) ?? [];
    String alias = bookMap['$fontPrefix${FontHelp.fontAliasSuffix}'] ?? '';
    final fontSizeVal = RxDouble(textFontSize(fontPrefix, bookMap));
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
                final size = await fontSize(bookId, fontPrefix, bookMap);
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
                var download = await DocHelp.tryCopyToDocDir(
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
                final localFolder = rootPath.joinPath(DocPath.getRelativePath(bookId).joinPath(download.folder));
                final filePath = localFolder.joinPath(download.name);

                var ok = await FontHelp.registerCustomFont(fileName, filePath);
                if (!ok) {
                  Snackbar.show(I18nKey.importFontFail.tr);
                  return;
                }

                bookMap['d'] = list.map((e) => e.toJson()).toList();
                bookMap['$fontPrefix${FontHelp.fontAliasSuffix}'] = fileName;
                bookMap['$fontPrefix${FontHelp.fontHashSuffix}'] = download.hash;
                await Db().db.bookDao.updateBookContent(bookId, jsonEncode(bookMap));

                fontDisplay.value = fileName;

                parentLogic.update(["RepeatLogic"]);
              },
              extra: fontDisplay.value.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () async {
                        bookMap['$fontPrefix${FontHelp.fontAliasSuffix}'] = "";
                        bookMap['$fontPrefix${FontHelp.fontHashSuffix}'] = "";

                        fontDisplay.value = "";

                        await Db().db.bookDao.updateBookContent(bookId, jsonEncode(bookMap));

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
    final fontSizeKey = "$fontPrefix${FontHelp.fontSizeSuffix}";
    if (map[fontSizeKey] != null) {
      return double.parse(map[fontSizeKey]);
    }
    return 17;
  }

  Future<double> fontSize(int bookId, String fontPrefix, Map<String, dynamic> map) async {
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
            text: I18nKey.btnSave.tr,
            onPressed: () async {
              final fontSizeKey = "$fontPrefix${FontHelp.fontSizeSuffix}";
              var bookMap = map;
              bookMap[fontSizeKey] = '${v.value}';
              await Db().db.bookDao.updateBookContent(bookId, jsonEncode(bookMap));
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
}
