import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/ssl.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/classroom_doc_help.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'sc_share_state.dart';

/// 课堂分享：和单本的 ScCrMaterialShareLogic 是一套做法（局域网 HTTPS + 导出 zip），
/// 只是文档换成整个课堂的，而且**全程流式**：
/// - 局域网：[ClassroomDocHelp.writeDoc] 直接写 HTTP response
/// - zip：先流式写成 index.json，再用 [Zip.compressStream] 一个文件一个文件打包
/// 课堂可能有几百 MB 媒体，任何"先在内存里拼好再落盘"的写法都会炸。
class ScShareLogic extends GetxController {
  static const int defaultPort = 4324;
  RxInt port = defaultPort.obs;
  static const String id = "ScShareLogic";
  final ScShareState state = ScShareState();
  HttpServer? _httpServer;

  @override
  void onInit() {
    super.onInit();
    state.classroom = Get.arguments[0] as Classroom;
    state.lanAddressSuffix = "/${DocPath.getIndexFileName()}";
    randCredentials(show: false);
  }

  Future<void> initPort() async {
    port.value = await Db().db.kvDao.getIntWithDefault(K.classroomSharePort, port.value);
    if (port.value > 50000) {
      port.value = defaultPort;
    }
  }

  void switchWeb(bool enable) {
    AwaitUtil.tryDo(() async {
      await initPort();
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
      var sslPath = await DocPath.getSslPath();
      var context = SelfSsl.generateSecurityContext(sslPath);
      _httpServer = await HttpServer.bindSecure(InternetAddress.anyIPv4, port.value, context);
      _httpServer!.listen((HttpRequest request) async {
        _handleRequest(request);
      });
    } catch (e) {
      await Db().db.kvDao.insertOrReplace(Kv(K.classroomSharePort, '${port.value + 10}'));
      Snackbar.show('Error starting HTTPS service: $e \n System has changed the port, please try again');
      _stopHttpService(tip: false);
      Get.back();
      return;
    }
    state.addresses.clear();
    for (var i = 0; i < ips.length; i++) {
      String ip = ips[i];
      state.addresses.add(Address("${I18nKey.labelLanAddress.tr} $i", 'https://$ip:${port.value}${state.lanAddressSuffix}'));
    }
    Snackbar.show('HTTPS service started');
    update([id]);
  }

  Future<void> _stopHttpService({tip = true}) async {
    if (_httpServer != null) {
      await _httpServer!.close();
      if (tip) {
        Snackbar.show('HTTPS service stopped');
      }
      _httpServer = null;
      update([id]);
    }
  }

  void randCredentials({bool show = true}) {
    state.user.value = StringUtil.generateRandom09(3);
    state.password.value = StringUtil.generateRandom09(6);
    update([id]);
    if (show) {
      MsgBox.yes(
        I18nKey.keyTitle.tr,
        I18nKey.keyContent.trParams([state.user.value, state.password.value]),
        yes: () {
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
        ..headers.set('WWW-Authenticate', 'Basic realm="GsClassroomShare"')
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
      var base = request.requestedUri.toString().substring(0, rootIndex).joinPath('${state.classroom.id}');
      // 直接写进 response，不经过中间字符串
      await ClassroomDocHelp.writeDoc(
        classroomId: state.classroom.id,
        sink: response,
        note: state.shareNote.value,
        databaseData: false,
        rootUrl: (book, index) => base.joinPath('${book.id}'),
      );
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
        String? password = await MsgBox.password(I18nKey.labelZipPassword.tr, I18nKey.labelZipPasswordOptional.tr);
        if (password == null) {
          Get.back();
          return;
        }
        await showOverlay(
          () async {
            var permissionStatus = await Permission.manageExternalStorage.request();
            if (permissionStatus != PermissionStatus.granted) {
              Snackbar.show(I18nKey.labelStoragePermissionDenied.tr);
              return;
            }

            final classroomId = state.classroom.id;
            var rootPath = await DocPath.getContentPath();
            var classroomPath = rootPath.joinPath('$classroomId');
            var indexFilePath = classroomPath.joinPath(DocPath.getIndexFileName());

            // 1. 整个课堂流式写成 index.json
            final indexFile = File(indexFilePath);
            final sink = indexFile.openWrite();
            List<ClassroomBookDownload>? books;
            try {
              books = await ClassroomDocHelp.writeDoc(
                classroomId: classroomId,
                sink: sink,
                note: state.shareNote.value,
                databaseData: false,
                rootUrl: null,
              );
            } finally {
              await sink.close();
            }
            if (books == null) {
              Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["classroom"]));
              return;
            }

            // 2. zip 名字用 index.json 的 hash（流式读文件算，不用把内容拿进内存）
            String indexHash = await Hash.toSha1(indexFilePath);
            bool encrypted = password.isNotEmpty;
            String zipFileName = encrypted ? "$indexHash.enc.zip" : "$indexHash.zip";
            File zipFile = File(classroomPath.joinPath(zipFileName));

            // 3. 组装 zip 里的条目：媒体按书本在 'b' 数组里的下标分目录
            var rootFilePath = classroomPath.joinPath(DocPath.zipRootFile);
            await File(rootFilePath).writeAsString(json.encode(ZipRootDoc('')));

            final List<List<String>> entries = [
              [DocPath.getIndexFileName(), indexFilePath],
              [DocPath.zipRootFile, rootFilePath],
            ];
            for (final book in books) {
              final bookPath = classroomPath.joinPath('${book.bookId}');
              for (final download in book.downloads) {
                entries.add(['${book.index}'.joinPath(download.path), bookPath.joinPath(download.path)]);
              }
            }

            final receivePort = ReceivePort();
            await Isolate.spawn(
              _createZipFileInIsolate,
              {
                'sendPort': receivePort.sendPort,
                'entries': entries,
                'zipFilePath': zipFile.path,
                'password': password,
              },
            );
            final result = await receivePort.first as Map<String, dynamic>;
            if (result['error'] != null) {
              Snackbar.show("Error creating zip file: ${result['error']}");
              return;
            }

            selectedDirectory = await FilePicker.platform.getDirectoryPath(
              dialogTitle: I18nKey.labelSelectDirectoryToSave.trArgs([zipFileName]),
            );
            if (selectedDirectory != null) {
              try {
                String targetZipName = "${state.classroom.name}.zip";
                zipFile.copySync(selectedDirectory!.joinPath(targetZipName));
                Get.back();
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
      },
    );
    if (selectedDirectory != null) {
      MsgBox.yes(I18nKey.labelFileSaved.tr, selectedDirectory!);
    }
  }

  /// entries 是 [zip 内路径, 磁盘绝对路径] 的清单，逐个流式塞进 zip。
  static void _createZipFileInIsolate(Map<String, dynamic> message) async {
    SendPort sendPort = message['sendPort'];
    try {
      List<List<String>> entries = (message['entries'] as List).map((e) => (e as List).cast<String>()).toList();
      String zipFilePath = message['zipFilePath'];
      String password = message['password'];

      await Zip.compressStream(
        entries.map((e) => ZipArchive(path: e[0], file: File(e[1]))).toList(),
        File(zipFilePath),
        password: password,
      );

      sendPort.send({'success': true});
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }
  }
}
