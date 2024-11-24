import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr_content/gs_cr_content_logic.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import '../../common/file_util.dart';
import 'gs_cr_content_template_state.dart';

class GsCrContentTemplateLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentTemplateState state = GsCrContentTemplateState();

  @override
  void onInit() {
    super.onInit();
    state.items.add(GsCrContentTemplateState.qTemplate);
    state.items.add(GsCrContentTemplateState.aTemplate);
    state.items.add(GsCrContentTemplateState.qaTemplate);
  }

  @override
  void onClose() {
    super.onClose();
  }

  void onSave(String segmentJson) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mp3'],
    );
    var path = "";
    if (result != null && result.files.single.path != null) {
      path = result.files.single.path!;
    } else {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return;
    }

    var savePathObs = "".obs;
    var pathParts = path.split('/');
    pathParts.last;
    if (pathParts.length - 2 >= 0) {
      var savePath = pathParts[pathParts.length - 2].joinPath(pathParts.last.split(".").first);
      savePathObs = savePath.obs;
    }
    MsgBox.strInputWithYesOrNo(
      savePathObs,
      I18nKey.labelInputPathOfTwoLevel.tr,
      "path/filename",
      yes: () {
        Nav.back();
        var savePath = savePathObs.value;
        var parts = savePath.split("/");
        if (parts.length < 2 || parts[0].isEmpty || parts[1].isEmpty) {
          Snackbar.show(I18nKey.labelInputPathError.tr);
          return;
        }
        showOverlay(() async {
          var mediaFileExtension = path.split(".").last;
          var mediaFileUrl = GsCrContentTemplateState.defaultUrl;
          mediaFileUrl = "$mediaFileUrl$savePath.$mediaFileExtension";

          var mediaFileHash = await Hash.toSha1(path);

          var rootAndFile = parts.length > 1 ? [parts.first, parts.sublist(1).join("/")] : [savePath, ""];
          var root = rootAndFile[0];
          var fileName = rootAndFile[1];
          var indexJson = GsCrContentTemplateState.prefixTemplate.replaceAll('{path.0}', root);
          indexJson = indexJson.replaceAll('{path.1}', fileName);
          indexJson = indexJson.replaceAll('{file.hash}', mediaFileHash);
          indexJson = indexJson.replaceAll('{file.extension}', mediaFileExtension);
          indexJson += '$segmentJson\n';
          indexJson += GsCrContentTemplateState.suffixTemplate;

          var rootPath = await DocPath.getContentPath();
          rootPath = rootPath.joinPath(root);
          await Folder.ensureExists(rootPath);
          var indexJsonPath = "${rootPath.joinPath(fileName)}.json";
          var indexJsonUrl = GsCrContentTemplateState.defaultUrl;
          indexJsonUrl = "$indexJsonUrl${root.joinPath(fileName)}.json";
          var contentIndex = await Db().db.contentIndexDao.add(indexJsonUrl);
          if (contentIndex.url.isEmpty) {
            return;
          }
          File file = File(indexJsonPath);
          await file.writeAsString(indexJson, flush: true);
          var indexJsonHash = await Hash.toSha1(indexJsonPath);
          var mediaFilePath = "${rootPath.joinPath(fileName)}.$mediaFileExtension";
          await FileUtil.copy(path, mediaFilePath);

          await Db().db.docDao.insertDoc(Doc(indexJsonUrl, indexJsonPath, indexJsonHash));
          await Db().db.docDao.insertDoc(Doc(mediaFileUrl, mediaFilePath, mediaFileHash));
          final logic = Get.find<GsCrContentLogic>();
          logic.init();
          Nav.gsCrContent.until();
        }, I18nKey.labelSaving.tr);
      },
    );
  }
}
