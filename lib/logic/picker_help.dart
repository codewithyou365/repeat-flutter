import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class PickerHelp {
  static Future<DownloadContent?> tryCopy({
    required int bookId,
    required FilePickerResult? result,
    required List<String> allowedExtensions,
  }) async {
    String pickedPath = "";
    String pickedName = "";
    if (result != null && result.files.single.path != null) {
      pickedPath = result.files.single.path!;
      pickedName = result.files.single.name;
    } else {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return null;
    }

    try {
      String hash = await Hash.toSha1(pickedPath);
      DownloadContent download = DownloadContent(url: ".${pickedName.split('.').last}", hash: hash);
      var rootPath = await DocPath.getContentPath();
      String localFolder = rootPath.joinPath(DocPath.getRelativePath(bookId).joinPath(download.folder));
      if (!allowedExtensions.containsIgnoreCase(download.extension)) {
        Snackbar.show(I18nKey.labelFileExtensionNotMatch.trArgs([jsonEncode(allowedExtensions)]));
        return null;
      }

      await Folder.ensureExists(localFolder);
      await File(pickedPath).copy(localFolder.joinPath(download.name));
      return download;
    } catch (e) {
      Snackbar.show(e.toString());
      return null;
    }
  }
}
