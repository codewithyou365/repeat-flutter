import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/import_help.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/page/content/content_logic.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'book_editor_state.dart';

class BookEditorLogic extends GetxController {
  static const int port = 40321;
  static const String id = "BookEditorLogic";
  final BookEditorState state = BookEditorState();
  HttpServer? _httpServer;

  @override
  void onInit() {
    super.onInit();
    state.book = Get.arguments[0] as BookShow;
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
    Snackbar.show('HTTP service started1');
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
        ..headers.set('WWW-Authenticate', 'Basic realm="BookEditor"')
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
    final Map<String, bool> map = {
      "/ace.js": true,
      "/json-source-map.js": true,
      "/keybinding-vim.min.js": true,
      "/mode-json.js": true,
      "/theme-github.js": true,
      "/worker-json.js": true,
    };

    if (map[path] == true) {
      response.headers.set('Content-Type', 'application/javascript');
      ByteData content = await rootBundle.load('assets/editor/$path');
      String str = utf8.decode(content.buffer.asUint8List());
      response.write(str);
      await response.close();
      return;
    }
    if (path == state.lanAddressSuffix) {
      String userAgent = request.headers.value('user-agent') ?? 'Unknown';
      if (userAgent == DownloadConstant.userAgent) {
        response.headers.set('Content-Disposition', 'attachment; filename="${pathVerses.last}"');
      } else {
        response.headers.set('Content-Disposition', 'inline');
      }

      var rootIndex = request.requestedUri.toString().lastIndexOf('/');
      var url = request.requestedUri.toString().substring(0, rootIndex);
      url = url.joinPath(Classroom.curr.toString());
      url = url.joinPath(state.book.bookId.toString());

      Map<String, dynamic> docMap = {};
      bool success = await DocHelp.getDocMapFromDb(
        bookId: state.book.bookId,
        ret: docMap,
        note: true,
        databaseData: true,
        rootUrl: url,
      );

      if (!success) {
        response.statusCode = HttpStatus.internalServerError;
        response.write('Failed to get book.');
        await response.close();
        return;
      }

      // Serve HTML editor page
      response.headers.contentType = ContentType.html;
      const indentEncoder = JsonEncoder.withIndent('  ');
      String prettyJsonString = indentEncoder.convert(docMap);
      ByteData content = await rootBundle.load('assets/editor/index.html');
      String htmlString = utf8.decode(content.buffer.asUint8List());
      String finalHtml = htmlString.replaceAll('{{BOOK}}', prettyJsonString);
      response.write(finalHtml);
      await response.close();
      return;
    } else if (path == "/upload") {
      try {
        final content = await utf8.decoder.bind(request).join();
        final Map<String, dynamic> jsonData = jsonDecode(content);

        var result = await ImportHelp.reimport(state.book.bookId, jsonData);
        if (!result) {
          response.statusCode = HttpStatus.expectationFailed;
          response.write("Upload failed.");
          return;
        }
        await Get.find<GsCrLogic>().init();
        await Get.find<ContentLogic>().change();
        response.statusCode = HttpStatus.ok;
        response.write("Upload successful. Received ${jsonData.length} keys.");
      } catch (e, st) {
        response.statusCode = HttpStatus.badRequest;
        response.write("Invalid JSON: $e");
        print("Upload error: $e\n$st");
      }
      await response.close();
    }
  }
}
