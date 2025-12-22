import 'dart:io';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/node.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'constant.dart';
import 'controller/heart.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'user.dart';

class WebServer {
  bool open = false;
  late final Server<EditorUser> server;
  final Map<String, String> keyToLocalPath = {};
  final List<String> ips = [];

  WebServer() {
    server = Server(wsEvent: wsEvent, kickPath: Path.kick);
  }

  Future<int> start(int port, Future<EditorUser?> Function(HttpRequest request) auth, Future<void> Function(HttpRequest request) handleHttpRequest) async {
    try {
      await server.start(port, auth, handleHttpRequest);
      server.logger = Snackbar.show;
      server.controllers[Path.heart] = (request) => withUser(request, heart);
      open = true;
    } catch (e) {
      Snackbar.show('Error starting HTTPS service: $e');
      return 0;
    }
    return port;
  }

  void wsEvent(WsEvent event) {}

  Future<void> stop() async {
    try {
      await server.stop();
      open = false;
    } catch (e) {
      Snackbar.show('Error starting HTTPS service: $e');
      return;
    }
  }

  EditorUser? getUser(message.Request req) {
    String? hashCodeStr = req.headers[message.Header.wsHashCode.name];
    if (hashCodeStr == null) {
      return null;
    }
    int hashCodeInt = int.parse(hashCodeStr);
    Node<EditorUser>? node = server.nodes.get(hashCodeInt);
    if (node == null) {
      return null;
    }
    EditorUser? user = node.user;
    return user;
  }

  Future<message.Response?> withUser(message.Request req, Future<message.Response?> Function(message.Request req, EditorUser user) handle) async {
    var user = getUser(req);
    if (user == null) {
      return message.Response(error: WebServerError.tokenExpired.name);
    }
    return await handle(req, user);
  }

  void broadcast(message.Request request) {
    if (open) {
      server.broadcast(request);
    }
  }
}
