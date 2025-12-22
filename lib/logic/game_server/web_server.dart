import 'dart:io';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:flutter/services.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/common/ws/node.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/blank_it_right_2_blank.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/blank_it_right_1_content.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/blank_it_right_0_settings.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/blank_it_right_3_submit.dart';
import 'package:repeat_flutter/logic/game_server/controller/game_user_score.dart';
import 'package:repeat_flutter/logic/game_server/controller/game_user_score_history.dart';
import 'package:repeat_flutter/logic/game_server/controller/game_user_score_minus.dart';
import 'package:repeat_flutter/logic/game_server/controller/type/type_verse_content.dart';
import 'package:repeat_flutter/logic/game_server/controller/type/type_game_settings.dart';
import 'package:repeat_flutter/logic/widget/game/game_state.dart';
import 'controller/heart.dart';
import 'controller/game_user_history.dart';
import 'controller/entry_game.dart';
import 'controller/login_or_register.dart';
import 'controller/submit.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:path/path.dart' as path;

class WebServer {
  bool open = false;
  late final Server<GameUser> server;
  final Map<String, String> keyToLocalPath = {};
  final List<String> ips = [];

  WebServer() {
    server = Server(wsEvent: wsEvent, kickPath: Path.kick);
  }

  Future<int> start() async {
    var port = 4321;
    try {
      await server.start(port, authByToken, _serveFile);
      server.logger = Snackbar.show;
      server.controllers[Path.loginOrRegister] = loginOrRegister;
      server.controllers[Path.entryGame] = (request) => withGameUser(request, entryGame);
      server.controllers[Path.heart] = (request) => withGameUser(request, heart);
      server.controllers[Path.gameUserHistory] = (request) => withGameUser(request, gameUserHistory);
      server.controllers[Path.submit] = (request) => withGameUser(request, submit);
      server.controllers[Path.gameUserScore] = (request) => withGameUser(request, gameUserScore);
      server.controllers[Path.gameUserScoreHistory] = (request) => withGameUser(request, gameUserScoreHistory);
      server.controllers[Path.gameUserScoreMinus] = (request) => withGameUser(request, gameUserScoreMinus);
      server.controllers[Path.typeGameSettings] = (request) => withGameUserAndGameType(request, GameType.type, typeGameSettings);
      server.controllers[Path.typeVerseContent] = (request) => withGameUserAndGameType(request, GameType.type, typeVerseContent);
      server.controllers[Path.blankItRightSettings] = (request) => withGameUserAndGameType(request, GameType.blankItRight, blankItRightSettings);
      server.controllers[Path.blankItRightContent] = (request) => withGameUserAndGameType(request, GameType.blankItRight, blankItRightContent);
      server.controllers[Path.blankItRightBlank] = (request) => withGameUserAndServer(request, GameType.blankItRight, blankItRightBlank);
      server.controllers[Path.blankItRightSubmit] = (request) => withGameUserAndServer(request, GameType.blankItRight, blankItRightSubmit);
      open = true;
    } catch (e) {
      Snackbar.show('Error starting HTTPS service: $e');
      return 0;
    }
    return port;
  }

  void wsEvent(WsEvent event) {
    EventBus().publish(EventTopic.wsEvent, event);
  }

  Future<void> stop() async {
    try {
      await server.stop();
      open = false;
    } catch (e) {
      Snackbar.show('Error starting HTTPS service: $e');
      return;
    }
  }

  Future<void> _serveFile(HttpRequest request) async {
    final requestedPath = request.uri.path == '/' ? '/index.html' : request.uri.path;
    // If it is necessary to access a local file, use a random key to map the local file path.
    if (keyToLocalPath.containsKey(requestedPath)) {
      var localPath = keyToLocalPath[requestedPath];
      // TODO...
    }
    final filePath = GameConstant.assetsPath.joinPath(requestedPath);
    var contentType = _getContentType(filePath);
    if (contentType.isEmpty) {
      request.response.redirect(Uri(path: "/"));
      await request.response.close();
      return;
    }
    try {
      ByteData content = await rootBundle.load(filePath);
      request.response
        ..headers.contentType = ContentType.parse(_getContentType(filePath))
        ..add(content.buffer.asInt8List());
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
    return user;
  }

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
    return await handle(req, user);
  }

  Future<message.Response?> withGameUserAndGameType(message.Request req, GameType gameType, Future<message.Response?> Function(message.Request req, GameUser user) handle) async {
    if (GameState.lastGameIndex != gameType.index) {
      return message.Response(error: GameServerError.gameNotFound.name);
    }
    var user = getGameUser(req);
    if (user == null) {
      return message.Response(error: GameServerError.tokenExpired.name);
    }
    return await handle(req, user);
  }

  Future<message.Response?> withGameUserAndServer(message.Request req, GameType gameType, Future<message.Response?> Function(message.Request req, GameUser user, Server<GameUser> server) handle) async {
    if (GameState.lastGameIndex != gameType.index) {
      return message.Response(error: GameServerError.gameNotFound.name);
    }
    var user = getGameUser(req);
    if (user == null) {
      return message.Response(error: GameServerError.tokenExpired.name);
    }
    return await handle(req, user, server);
  }
}
