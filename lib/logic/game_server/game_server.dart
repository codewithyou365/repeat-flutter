import 'dart:io';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:flutter/services.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/common/ws/node.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/controller/get_edit_status.dart';
import 'package:repeat_flutter/logic/game_server/controller/get_segment_content.dart';
import 'package:repeat_flutter/logic/game_server/controller/set_segment_content.dart';
import 'controller/heart.dart';
import 'controller/game_user_history.dart';
import 'controller/entry_game.dart';
import 'controller/login_or_register.dart';
import 'controller/submit.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:path/path.dart' as path;

class GameServer {
  Server<GameUser> server = Server();
  Map<String, String> keyToLocalPath = {};
  List<String> ips = [];

  Future<int> start() async {
    var port = 40321;
    try {
      server.start(port, authByToken, _serveFile);
      server.logger = Snackbar.show;
      server.controllers[Path.loginOrRegister] = loginOrRegister;
      server.controllers[Path.entryGame] = (request) => withGameUser(request, entryGame);
      server.controllers[Path.heart] = (request) => withGameUser(request, heart);
      server.controllers[Path.gameUserHistory] = (request) => withGameUser(request, gameUserHistory);
      server.controllers[Path.submit] = (request) => withGameUser(request, submit);
      server.controllers[Path.getEditStatus] = (request) => withGameUser(request, getEditStatus);
      server.controllers[Path.getSegmentContent] = (request) => withGameUser(request, getSegmentContent);
      server.controllers[Path.setSegmentContent] = (request) => withGameUserAndServer(request, setSegmentContent);
    } catch (e) {
      Snackbar.show('Error starting HTTP service: $e');
      return 0;
    }
    return port;
  }

  Future<void> stop() async {
    try {
      await server.stop();
    } catch (e) {
      Snackbar.show('Error starting HTTP service: $e');
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
      default:
        return 'application/octet-stream'; // Default binary content type
    }
  }

  Future<GameUser?> authByToken(HttpRequest request) async {
    var token = request.uri.queryParameters['token'];
    if (token == null) {
      return null;
    }
    final user = await Db().db.gameUserDao.loginByToken(token);
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
    Node<GameUser>? node = server.nodes[hashCodeInt];
    if (node == null) {
      return null;
    }
    GameUser? user = node.user;
    return user;
  }

  withGameUser(message.Request req, Future<message.Response?> Function(message.Request req, GameUser? user) handle) {
    return handle(req, getGameUser(req));
  }

  withGameUserAndServer(message.Request req, Future<message.Response?> Function(message.Request req, GameUser? user, Server<GameUser> server) handle) {
    return handle(req, getGameUser(req), server);
  }
}
