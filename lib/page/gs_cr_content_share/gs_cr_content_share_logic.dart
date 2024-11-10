import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/constant.dart';
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
    List<String> arguments = Get.arguments as List<String>;
    state.rawUrl = arguments[0];
    state.addresses.add(Address(I18nKey.labelOriginalAddress.tr, state.rawUrl));

    if (arguments.length > 1) {
      state.lanAddressSuffix = "/${arguments[1].replaceAll(RegExp(r'^/+'), '')}";
    }
    if (arguments.length > 2) {
      state.manifestJson = arguments[2];
    }
    if (state.lanAddressSuffix.isNotEmpty) {
      _startHttpService();
    }
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
      var rootPath = await DocPath.getContentPath();
      var repeatDocPath = rootPath.joinPath(state.lanAddressSuffix);
      var kv = await RepeatDoc.fromPath(repeatDocPath, Uri.parse(state.rawUrl));
      if (kv == null) {
        Snackbar.show(I18nKey.labelDownloadFirstBeforeSaving.tr);
        return;
      }

      print("${DateTime.now()}");
      var name = Url.toDocName(state.rawUrl);
      List<ZipArchive> zipFiles = [ZipArchive(File(repeatDocPath), name)];
      var zipSavePath = await DocPath.getZipSavePath(clearFirst: true);
      var indexFilePath = zipSavePath.joinPath(DocPath.zipIndexFile);
      var indexContent = ZipIndexDoc(name, state.rawUrl);
      var indexFile = File(indexFilePath);
      zipFiles.add(ZipArchive(await indexFile.writeAsString(json.encode(indexContent)), DocPath.zipIndexFile));

      rootPath = rootPath.joinPath(kv.rootPath);
      for (var v in kv.lesson) {
        var targetPath = rootPath.joinPath(v.path);
        zipFiles.add(ZipArchive(File(targetPath), v.path));
      }
      String zipFileName = "${name.trimFormat()}.zip";
      File zipFile = File(zipSavePath.joinPath(zipFileName));
      await Zip.compress(zipFiles, zipFile);
      selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: I18nKey.labelSelectDirectoryToSave.trArgs([zipFileName]),
      );
      if (selectedDirectory != null) {
        try {
          zipFile.copySync(selectedDirectory!.joinPath(zipFileName));
          Snackbar.show(I18nKey.labelSaveSuccess.trArgs([zipFileName]));
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
