import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

class FontHelp {
  static const fontAliasSuffix = "FontAlias";
  static const fontHashSuffix = "FontHash";
  static const fontSizeSuffix = "FontSize";

  static Future<void> registerAllFont() async {
    try {
      var books = await Db().db.bookDao.getAll(Classroom.curr);
      final rootPath = await DocPath.getContentPath();
      for (var s in books) {
        if (s.content.isEmpty) continue;

        Map<String, dynamic> bookMap = jsonDecode(s.content);
        List<DownloadContent> downloads = DownloadContent.toList(bookMap['d']) ?? [];

        const prefixes = ["q", "t", "a", "n"];

        for (var prefix in prefixes) {
          String alias = bookMap['$prefix$fontAliasSuffix'] ?? '';
          String hash = bookMap['$prefix$fontHashSuffix'] ?? '';

          if (alias.isNotEmpty && hash.isNotEmpty) {
            final download = downloads.firstWhereOrNull((e) => e.hash == hash);
            if (download != null) {
              final localFolder = rootPath.joinPath(DocPath.getRelativePath(s.id!).joinPath(download.folder));
              final filePath = localFolder.joinPath(download.name);

              await registerCustomFont(alias, filePath);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error registering fonts: $e");
    }
  }

  static Future<bool> registerCustomFont(String alias, String filePath) async {
    try {
      final File fontFile = File(filePath);
      if (!await fontFile.exists()) return false;

      final Uint8List fontBytes = await fontFile.readAsBytes();

      final fontLoader = FontLoader(alias);

      fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));

      await fontLoader.load();
    } catch (e) {
      return false;
    }
    return true;
  }
}
