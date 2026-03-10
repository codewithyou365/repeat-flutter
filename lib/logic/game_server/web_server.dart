import 'dart:io';
import 'dart:ui';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/common/ws/node.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/controller/game.dart';
import 'package:repeat_flutter/logic/game_server/controller/game_admin_id.dart';
import 'package:repeat_flutter/logic/game_server/controller/game_user_score.dart';
import 'package:repeat_flutter/logic/game_server/controller/game_user_score_history.dart';
import 'package:repeat_flutter/logic/game_server/controller/game_user_score_minus.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'controller/game_key.dart';
import 'controller/heart.dart';
import 'controller/js/js_runtime.dart';
import 'controller/login_or_register.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart';

class WebServer {
  bool open = false;
  late final Server<GameUser> server;
  final List<String> ips = [];
  String destinationDir = '';
  late JsRuntime jsRuntime;

  WebServer({
    required VoidCallback tapLeft,
    required VoidCallback tapRight,
    required VoidCallback tapMiddle,
    required VoidCallback longTapMiddle,
  }) {
    jsRuntime = JsRuntime(
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
    DownloadContent download = DownloadContent(url: '', hash: hash);
    destinationDir = localFolder.joinPath(download.folder).joinPath(download.pureName);

    final file = File(destinationDir.joinPath('service.js'));
    var content = '';
    if (await file.exists()) {
      content = await file.readAsString();
    }
    await jsRuntime.init(content);
    await server.start(port, authByToken, _serveFile);
    server.logger = Snackbar.show;
    server.controllers[Path.loginOrRegister] = loginOrRegister;
    server.controllers[Path.gameKey] = (request) => withGameUser(request, gameKey);
    server.controllers[Path.heart] = (request) => withGameUser(request, heart);
    server.controllers[Path.gameAdminId] = (request) => withGameUser(request, gameAdminId);
    server.controllers[Path.game] = (request) => withGameUserAndServer(request, game);
    server.controllers[Path.gameUserScoreHistory] = (request) => withGameUser(request, gameUserScoreHistory);
    server.controllers[Path.gameUserScore] = (request) => withGameUser(request, gameUserScore);
    server.controllers[Path.gameUserScoreMinus] = (request) => withGameUser(request, gameUserScoreMinus);

    open = true;

    return;
  }

  void wsEvent(WsEvent event) {
    EventBus().publish(EventTopic.wsEvent, event);
  }

  Future<void> stop() async {
    try {
      await server.stop();
      jsRuntime.dispose();
      open = false;
    } catch (e) {
      Snackbar.show('Error starting HTTPS service: $e');
      return;
    }
  }

  Future<void> _serveFile(HttpRequest request) async {
    final requestedPath = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final filePath = destinationDir.joinPath(requestedPath);
    var contentType = _getContentType(filePath);
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

  Future<GameUser?> authByToken(HttpRequest request) async {
    var token = request.uri.queryParameters['token'];
    if (token == null) {
      return null;
    }
    final user = await Db().db.gameUserDao.authByToken(token);
    if (user.isEmpty()) {
      return null;
    }
    var gamePassword = await Db().db.kvDao.getStr(K.gamePassword) ?? '';
    if (gamePassword.isNotEmpty) {
      final gamePasswordCreateTime = await Db().db.kvDao.getInt(K.gamePasswordCreateTime) ?? 0;
      if (user.tokenExpiredDate < gamePasswordCreateTime) {
        return null;
      }
    }
    return user;
  }

  final Lock lock = Lock();

  // critical section

  GameUser? getGameUser(message.Request req) {
    String? hashCodeStr = req.headers[Header.wsHashCode.name];
    if (hashCodeStr == null) {
      return null;
    }
    int hashCodeInt = int.parse(hashCodeStr);
    Node<GameUser>? node = server.nodes.get(hashCodeInt);
    if (node == null) {
      return null;
    }
    GameUser? user = node.user;
    return user;
  }

  Future<message.Response?> withGameUser(message.Request req, Future<message.Response?> Function(message.Request req, GameUser user) handle) async {
    var user = getGameUser(req);
    if (user == null) {
      return message.Response(error: GameServerError.tokenExpired.name);
    }
    return await lock.synchronized(() async {
      return await handle(req, user);
    });
  }

  Future<message.Response?> withGameUserAndServer(message.Request req, Future<message.Response?> Function(message.Request req, GameUser user, Server<GameUser> server, JsRuntime jsRuntime) handle) async {
    var user = getGameUser(req);
    if (user == null) {
      return message.Response(error: GameServerError.tokenExpired.name);
    }
    return await lock.synchronized(() async {
      return await handle(req, user, server, jsRuntime);
    });
  }
}
