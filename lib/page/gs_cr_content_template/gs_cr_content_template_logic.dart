import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr_content/gs_cr_content_logic.dart';
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
    List<int> ids = Get.arguments as List<int>;
    state.contentId = ids[0];
    state.contentSerial = ids[1];
    state.items.add(GsCrContentTemplateState.qTemplate);
    state.items.add(GsCrContentTemplateState.aTemplate);
    state.items.add(GsCrContentTemplateState.qaTemplate);
  }

  void onSave(String segmentJson) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mp3'],
    );
    var mediaRawPath = "";
    if (result != null && result.files.single.path != null) {
      mediaRawPath = result.files.single.path!;
    } else {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return;
    }
    showOverlay(() async {
      var rootPath = await DocPath.getContentPath();
      var relativePath = DocPath.getRelativePath(state.contentSerial);
      var workPath = rootPath.joinPath(relativePath);
      await Folder.ensureExists(workPath);

      var mediaFileExtension = mediaRawPath.split(".").last;
      var mediaFileUrl = GsCrContentTemplateState.defaultUrl.joinPath(relativePath).joinPath('0.$mediaFileExtension');
      var mediaFilePathInDb = relativePath.joinPath('0.$mediaFileExtension');
      var mediaFilePath = workPath.joinPath('0.$mediaFileExtension');
      var mediaFileHash = await Hash.toSha1(mediaRawPath);
      var ok = await FileUtil.copy(mediaRawPath, mediaFilePath);
      if (!ok) {
        return;
      }
      await Db().db.docDao.insertDoc(Doc(mediaFileUrl, mediaFilePathInDb, mediaFileHash));

      var indexJsonContent = GsCrContentTemplateState.prefixTemplate;
      indexJsonContent = indexJsonContent.replaceAll('{file.extension}', mediaFileExtension);
      indexJsonContent = indexJsonContent.replaceAll('{file.hash}', mediaFileHash);
      indexJsonContent += '$segmentJson\n';
      indexJsonContent += GsCrContentTemplateState.suffixTemplate;
      var indexJsonUrl = GsCrContentTemplateState.defaultUrl.joinPath(relativePath).joinPath('index.json');
      var indexJsonPathInDb = relativePath.joinPath('index.json');
      var indexJsonPath = workPath.joinPath('index.json');
      File indexJsonFile = File(indexJsonPath);
      await indexJsonFile.writeAsString(indexJsonContent, flush: true);
      var indexJsonHash = await Hash.toSha1(indexJsonPath);
      await Db().db.docDao.insertDoc(Doc(indexJsonUrl, indexJsonPathInDb, indexJsonHash));
      var indexJsonDocId = await Db().db.docDao.getIdByPath(indexJsonPathInDb);
      if (indexJsonDocId == null) {
        return;
      }

      final logic = Get.find<GsCrContentLogic>();
      await logic.schedule(state.contentId, indexJsonDocId, indexJsonUrl);
      Nav.gsCrContent.until();
    }, I18nKey.labelSaving.tr);
  }
}
