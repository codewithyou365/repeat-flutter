import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repeat_flutter/common/file_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_content_share_state.dart';

class GsCrContentShareLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentShareState state = GsCrContentShareState();
  HttpServer? _httpServer;

  @override
  void onInit() {
    super.onInit();
    state.content = Get.arguments[0] as Content;
    state.manifestJson = Get.arguments[1] as String;
    state.addresses.add(Address(I18nKey.labelOriginalAddress.tr, state.content.url));
    state.lanAddressSuffix = "/${DocPath.getIndexFileName()}";
    _startHttpService();
  }

  @override
  void onClose() {
    super.onClose();
    if (state.lanAddressSuffix.isNotEmpty) {
      _stopHttpService();
    }
  }

  Future<void> _startHttpService() async {
    var port = 40321;
    List<String> ips = [];
    try {
      ips = await getLanIps();
    } catch (e) {
      Snackbar.show('Error getting LAN IP : $e');
      return;
    }

    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _httpServer!.listen((HttpRequest request) async {
        _handleRequest(request);
      });
    } catch (e) {
      Snackbar.show('Error starting HTTP service: $e');
      return;
    }
    for (var i = 0; i < ips.length; i++) {
      String ip = ips[i];
      state.addresses.add(Address("${I18nKey.labelLanAddress.tr} $i", 'http://$ip:$port${state.lanAddressSuffix}'));
    }
    update([id]);
  }

  Future<void> _stopHttpService() async {
    if (_httpServer != null) {
      await _httpServer!.close();
      Snackbar.show('HTTP service stopped');
      _httpServer = null;
    }
  }

  void _handleRequest(HttpRequest request) async {
    final response = request.response;
    if (request.uri.path == '/___hello_world') {
      response.statusCode = HttpStatus.ok;
      response.write('{"message": "Hello, World!"}');
    } else {
      await _serveFile(request.uri.pathSegments, request);
    }

    await response.close();
  }

  Future<List<String>> getLanIps() async {
    List<String> ret = [];
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          ret.add(addr.address);
        }
      }
    }
    return ret; // Fallback if no LAN IP found
  }

  Future<void> _serveFile(List<String> pathSegments, HttpRequest request) async {
    var response = request.response;
    var path = Url.toPath(pathSegments);
    if (state.manifestJson != "" && path == state.lanAddressSuffix) {
      String userAgent = request.headers.value('user-agent') ?? 'Unknown';
      response.headers.contentType = ContentType.json;
      if (userAgent == Download.userAgent) {
        response.headers.set('Content-Disposition', 'attachment; filename="${pathSegments.last}"');
      } else {
        response.headers.set('Content-Disposition', 'inline');
      }
      response.write(state.manifestJson);
      return;
    }
    var directory = await DocPath.getContentPath();
    var filePath = directory.joinPath(path);
    final file = File(filePath);
    if (await file.exists()) {
      response.headers.contentType = ContentType.binary;
      response.headers.set('Content-Disposition', 'attachment; filename="${file.uri.pathSegments.last}"');
      await file.openRead().pipe(response);
    } else {
      response
        ..statusCode = HttpStatus.notFound
        ..write('File not found');
    }
  }

  void onSave() async {
    String? selectedDirectory;
    await showOverlay(() async {
      var permissionStatus = await Permission.storage.request();
      if (permissionStatus != PermissionStatus.granted) {
        Snackbar.show(I18nKey.labelStoragePermissionDenied.tr);
        return;
      }
      String indexPath = DocPath.getRelativeIndexPath(state.content.serial);
      var kv = await RepeatDoc.fromPath(indexPath);
      if (kv == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSaving.tr);
        return;
      }

      var rootPath = await DocPath.getContentPath();
      String indexFilePath = rootPath.joinPath(indexPath);

      // for root file
      String relativePath = DocPath.getRelativePath(state.content.serial);
      List<Doc> docs = await Db().db.docDao.getAllDoc("$relativePath/");
      Doc indexDoc = docs.firstWhere((doc) => doc.path == indexPath, orElse: () => Doc('', '', ''));
      if (indexDoc.hash == "") {
        Snackbar.show(I18nKey.labelDataAnomaly.tr);
        return;
      }
      String zipFileName = "${indexDoc.hash}.zip";
      File zipFile = File(rootPath.joinPath(relativePath).joinPath(zipFileName));
      bool zipFileExist = await zipFile.exists();
      if (!zipFileExist) {
        var rootFilePath = rootPath.joinPath(relativePath).joinPath(DocPath.zipRootFile);
        var rootFileContent = ZipRootDoc(docs, state.content.url);
        var rootFile = File(rootFilePath);
        rootFile = await rootFile.writeAsString(json.encode(rootFileContent));

        List<ZipArchive> zipFiles = [];
        zipFiles.add(ZipArchive(File(indexFilePath), FileUtil.toFileName(indexFilePath)));
        zipFiles.add(ZipArchive(File(rootFilePath), FileUtil.toFileName(rootFilePath)));
        for (var lessonIndex = 0; lessonIndex < kv.lesson.length; lessonIndex++) {
          var v = kv.lesson[lessonIndex];
          var mediaFileName = DocPath.getMediaFileName(lessonIndex, v.mediaExtension);
          zipFiles.add(ZipArchive(File(rootPath.joinPath(relativePath).joinPath(mediaFileName)), mediaFileName));
        }
        await Zip.compress(zipFiles, zipFile);
      }

      selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: I18nKey.labelSelectDirectoryToSave.trArgs([zipFileName]),
      );
      if (selectedDirectory != null) {
        try {
          String targetZipName = "${Classroom.currName}-${state.content.name}.zip";
          zipFile.copySync(selectedDirectory!.joinPath(targetZipName));
          Snackbar.show(I18nKey.labelSaveSuccess.trArgs([targetZipName]));
        } catch (e) {
          selectedDirectory = null;
          Snackbar.show(I18nKey.labelDirectoryPermissionDenied.trArgs([selectedDirectory!]));
        }
      } else {
        Snackbar.show(I18nKey.labelSaveCancel.tr);
      }
    }, I18nKey.labelSaving.tr);

    if (selectedDirectory != null) {
      MsgBox.yes(I18nKey.labelFileSaved.tr, selectedDirectory!);
    }
  }
}
