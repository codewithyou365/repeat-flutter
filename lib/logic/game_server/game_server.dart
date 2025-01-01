import 'dart:io';
import 'package:flutter/services.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'controller/user_one_game_history.dart';
import 'controller/latest_game.dart';
import 'controller/login_or_register.dart';
import 'controller/submit.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:path/path.dart' as path;

class GameServer {
  Server server = Server();
  Map<int, WebSocket> clients = {};
  Map<int, WebSocket> realClients = {};
  List<String> ips = [];

  Future<int> start() async {
    var port = 40321;
    try {
      server.start(port, _serveFile);
      server.logger = Snackbar.show;
      server.controllers["loginOrRegister"] = loginOrRegister;
      server.controllers["latestGame"] = latestGame;
      server.controllers["userOneGameHistory"] = userOneGameHistory;
      server.controllers["submit"] = submit;
    } catch (e) {
      Snackbar.show('Error starting HTTP service: $e');
      return 0;
    }
    return port;
  }

  Future<void> stop() async {
    try {
      server.stop();
    } catch (e) {
      Snackbar.show('Error starting HTTP service: $e');
      return;
    }
  }

  Future<void> _serveFile(HttpRequest request) async {
    final requestedPath = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final filePath = GameServerPath.assetsPath.joinPath(requestedPath);
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
}
