import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/file_util.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'sc_cr_material_share_state.dart';

class ScCrMaterialShareLogic extends GetxController {
  static const int port = 40321;
  static const String id = "ScCrMaterialShareLogic";
  final ScCrMaterialShareState state = ScCrMaterialShareState();
  HttpServer? _httpServer;

  @override
  void onInit() {
    super.onInit();
    state.book = Get.arguments[0] as Book;
    state.original = Address(I18nKey.labelOriginalAddress.tr, state.book.url);
    state.lanAddressSuffix = "/${DocPath.getIndexFileName()}";
    randCredentials(show: false);
  }

  void switchWeb(bool enable) {
    AwaitUtil.tryDo(() async {
      state.addresses.clear();
      if (enable) {
        await _startHttpService();
      } else {
        await _stopHttpService();
      }
      state.webStart.value = enable;
    });
  }

  @override
  void onClose() {
    super.onClose();
    _stopHttpService();
  }

  Future<void> _startHttpService() async {
    List<String> ips = [];
    try {
      ips = await Ip.getLanIps();
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
    state.addresses.clear();
    for (var i = 0; i < ips.length; i++) {
      String ip = ips[i];
      state.addresses.add(Address("${I18nKey.labelLanAddress.tr} $i", 'http://$ip:$port${state.lanAddressSuffix}'));
    }
    Snackbar.show('HTTP service started');
    update([id]);
  }

  Future<void> _stopHttpService() async {
    if (_httpServer != null) {
      await _httpServer!.close();
      Snackbar.show('HTTP service stopped');
      _httpServer = null;
      update([id]);
    }
  }

  void randCredentials({bool show = true}) {
    state.user.value = StringUtil.generateRandom09(3);
    state.password.value = StringUtil.generateRandom09(6);
    if (show) {
      MsgBox.yes(
        I18nKey.keyTitle.tr,
        I18nKey.keyContent.trParams([state.user.value, state.password.value]),
        yes: () {
          randCredentials(show: false);
          Get.back();
        },
      );
    }
  }

  void _handleRequest(HttpRequest request) async {
    final response = request.response;
    final username = state.user.value;
    final password = state.password.value;

    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
    final expectedAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

    if (authHeader != expectedAuth) {
      response
        ..statusCode = HttpStatus.unauthorized
        ..headers.set('WWW-Authenticate', 'Basic realm="GsCrContentShare"')
        ..write('Unauthorized');
      await response.close();
      return;
    }

    if (request.uri.path == '/___hello_world') {
      response.statusCode = HttpStatus.ok;
      response.write('{"message": "Hello, World!"}');
    } else {
      await _serveFile(request.uri.pathSegments, request);
    }

    await response.close();
  }

  Future<void> _serveFile(List<String> pathVerses, HttpRequest request) async {
    var response = request.response;
    var path = Url.toPath(pathVerses);
    if (path == state.lanAddressSuffix) {
      String userAgent = request.headers.value('user-agent') ?? 'Unknown';
      response.headers.contentType = ContentType.json;
      if (userAgent == DownloadConstant.userAgent) {
        response.headers.set('Content-Disposition', 'attachment; filename="${pathVerses.last}"');
      } else {
        response.headers.set('Content-Disposition', 'inline');
      }
      var rootIndex = request.requestedUri.toString().lastIndexOf('/');
      var url = request.requestedUri.toString().substring(0, rootIndex);
      url = url.joinPath(Classroom.curr.toString());
      url = url.joinPath(state.book.id!.toString());
      Map<String, dynamic> docMap = {};
      bool success = await DocHelp.getDocMapFromDb(
        bookId: state.book.id!,
        ret: docMap,
        note: state.shareNote.value,
        rootUrl: url,
      );
      if (success == false) {
        return;
      }
      response.write(json.encode(docMap));
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
    RxBool shareNote = RxBool(state.shareNote.value);

    MsgBox.checkboxWithYesOrNo(
        title: I18nKey.labelTips.tr,
        select: shareNote,
        selectDesc: I18nKey.labelDoYourShareTheNotes.tr,
        yes: () async {
          await showOverlay(
            () async {
              var permissionStatus = await Permission.storage.request();
              if (permissionStatus != PermissionStatus.granted) {
                Snackbar.show(I18nKey.labelStoragePermissionDenied.tr);
                return;
              }

              String relativeIndexPath = DocPath.getRelativeIndexPath(state.book.id!);
              String relativePath = DocPath.getRelativePath(state.book.id!);
              var rootPath = await DocPath.getContentPath();

              Map<String, dynamic> docMap = {};
              bool success = await DocHelp.getDocMapFromDb(
                bookId: state.book.id!,
                ret: docMap,
                note: state.shareNote.value,
              );
              if (!success) {
                return;
              }

              var docText = json.encode(docMap);
              String indexHash = Hash.toSha1ForString(docText);
              String zipFilePath = "$indexHash.zip";
              File zipFile = File(rootPath.joinPath(relativePath).joinPath(zipFilePath));
              bool zipFileExist = await zipFile.exists();

              if (!zipFileExist) {
                var downloads = DocHelp.getDownloads(BookContent.fromJson(docMap));
                final receivePort = ReceivePort();
                await Isolate.spawn(
                  _createZipFileInIsolate,
                  {
                    'sendPort': receivePort.sendPort,
                    'downloads': downloads,
                    'docBytes': utf8.encode(docText),
                    'zipFilePath': zipFilePath,
                    'indexFilePath': rootPath.joinPath(relativeIndexPath),
                    'relativePath': relativePath,
                    'rootPath': rootPath,
                    'contentUrl': state.book.url,
                  },
                );

                // Wait for the isolate to complete
                final result = await receivePort.first as Map<String, dynamic>;
                if (result['error'] != null) {
                  Snackbar.show("Error creating zip file: ${result['error']}");
                  return;
                }
              }

              selectedDirectory = await FilePicker.platform.getDirectoryPath(
                dialogTitle: I18nKey.labelSelectDirectoryToSave.trArgs([zipFilePath]),
              );
              if (selectedDirectory != null) {
                try {
                  String targetZipName = "${Classroom.currName}-${state.book.name}.zip";
                  zipFile.copySync(selectedDirectory!.joinPath(targetZipName));
                  Snackbar.show(I18nKey.labelSaveSuccess.trArgs([targetZipName]));
                } catch (e) {
                  Snackbar.show(I18nKey.labelDirectoryPermissionDenied.trArgs([selectedDirectory!]));
                  selectedDirectory = null;
                }
              } else {
                Snackbar.show(I18nKey.labelSaveCancel.tr);
              }
            },
            I18nKey.labelSaving.tr,
          );
        });
    if (selectedDirectory != null) {
      MsgBox.yes(I18nKey.labelFileSaved.tr, selectedDirectory!);
    }
  }

  static void _createZipFileInIsolate(Map<String, dynamic> message) async {
    SendPort sendPort = message['sendPort'];
    try {
      List<DownloadContent> downloads = message['downloads'];
      Uint8List docBytes = message['docBytes'];
      String zipFilePath = message['zipFilePath'];
      String indexFilePath = message['indexFilePath'];
      String relativePath = message['relativePath'];
      String rootPath = message['rootPath'];
      String contentUrl = message['contentUrl'];

      var rootFilePath = rootPath.joinPath(relativePath).joinPath(DocPath.zipRootFile);
      var rootFileContent = ZipRootDoc(contentUrl);
      var rootFile = File(rootFilePath);
      await rootFile.writeAsString(json.encode(rootFileContent));

      File zipFile = File(rootPath.joinPath(relativePath).joinPath(zipFilePath));

      List<ZipArchive> zipFiles = [];
      zipFiles.add(ZipArchive(
        path: FileUtil.toFileName(indexFilePath),
        bytes: docBytes,
      ));
      zipFiles.add(ZipArchive(
        path: FileUtil.toFileName(rootFilePath),
        file: File(rootFilePath),
      ));
      for (var download in downloads) {
        zipFiles.add(ZipArchive(
          path: download.path,
          file: File(rootPath.joinPath(relativePath).joinPath(download.path)),
        ));
      }

      // Compress zip file
      await Zip.compress(zipFiles, zipFile);

      // Send success message back to main isolate
      sendPort.send({'success': true});
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }
  }
}
