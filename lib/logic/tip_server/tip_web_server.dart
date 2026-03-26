import 'dart:io';
import 'dart:ui';

import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/tip_server/controller/tip_key.dart';
import 'package:repeat_flutter/logic/tip_server/js/js_runtime.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/page/repeat/logic/tts_helper.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart';
import 'constant.dart';
import 'controller/heart.dart';
import 'controller/tip.dart';

class TipUser extends UserId {
  final int id;

  TipUser({required this.id});

  @override
  int getId() => id;
}

class TipWebServer {
  bool open = false;
  late final Server<TipUser> server;
  String destinationDir = '';
  late JsRuntime jsRuntime;
  final TtsHelper ttsHelper;

  TipWebServer({
    required this.ttsHelper,
    required bool Function() isMute,
    required VoidCallback tapNext,
    required VoidCallback tapLeft,
    required VoidCallback tapRight,
    required VoidCallback tapMiddle,
    required VoidCallback longTapMiddle,
  }) {
    jsRuntime = JsRuntime(
      isMute: isMute,
      ttsHelper: ttsHelper,
      tapNext: tapNext,
      tapLeft: tapLeft,
      tapRight: tapRight,
      tapMiddle: tapMiddle,
      longTapMiddle: longTapMiddle,
    );
    server = Server(wsEvent: wsEvent, kickPath: Path.kick);
  }

  Future<void> start(int bookId, String hash, String jsFile, int port) async {
    final rootPath = await DocPath.getContentPath();
    final localFolder = rootPath.joinPath(DocPath.getRelativePath(bookId));
    final download = DownloadContent(url: '', hash: hash);
    destinationDir = localFolder.joinPath(download.folder).joinPath(download.pureName);
    if (jsFile.isEmpty) {
      jsFile = 'service.js';
    }
    final file = File(destinationDir.joinPath(jsFile));
    var content = '';
    if (await file.exists()) {
      content = await file.readAsString();
    }

    await server.startLocal(port, (_) async {
      return TipUser(id: port);
    }, _serveFile);
    await jsRuntime.init(content, server);

    server.controllers[Path.heart] = (request) => withLock(request, heart);
    server.controllers[Path.contentKey] = (request) => withLock(request, tipKey);
    server.controllers[Path.tip] = (request) => withJsRuntime(request, tip);

    open = true;
  }

  void wsEvent(WsEvent event) {}

  Future<void> stop() async {
    try {
      await server.stop();
      jsRuntime.dispose();
      open = false;
    } catch (e) {
      return;
    }
  }

  Future<void> _serveFile(HttpRequest request) async {
    final requestedPath = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final filePath = destinationDir.joinPath(requestedPath);
    final contentType = _getContentType(filePath);
    if (contentType.isEmpty) {
      request.response.redirect(Uri(path: "/"));
      await request.response.close();
      return;
    }
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsBytes();
        request.response
          ..headers.contentType = ContentType.parse(contentType)
          ..add(content);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('404 Not Found');
      }
      await request.response.close();
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('404 Not Found');
      await request.response.close();
    }
  }

  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.html':
        return 'text/html';
      case '.css':
        return 'text/css';
      case '.js':
        return 'application/javascript';
      case '.json':
        return 'application/json';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.bin':
        return 'application/octet-stream';
      default:
        return '';
    }
  }

  final Lock lock = Lock();

  Future<message.Response?> withLock(message.Request req, Future<message.Response?> Function(message.Request req) handle) async {
    return await lock.synchronized(() async {
      return await handle(req);
    });
  }

  Future<message.Response?> withJsRuntime(
    message.Request req,
    Future<message.Response?> Function(message.Request req, JsRuntime jsRuntime) handle,
  ) async {
    return await lock.synchronized(() async {
      return await handle(req, jsRuntime);
    });
  }
}
