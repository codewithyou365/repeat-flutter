import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/logic/game_server/constant.dart';

import 'node.dart';

import 'message.dart';

enum ServerStatus {
  stopped,
  working,
}

class Server<User> {
  final cors = true;
  var status = ServerStatus.working;
  Logger? logger;
  HttpServer? server;
  final Map<String, Controller> controllers = {};
  final Map<int, Node<User>> nodes = {};

  Future<void> start(int port, Future<User?> Function(HttpRequest request) auth, Future<void> Function(HttpRequest request) handleHttpRequest) async {
    status = ServerStatus.working;
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, port);

      server!.listen((HttpRequest request) async {
        if (status == ServerStatus.stopped) return;
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          User? user = await auth(request);
          WebSocket socket = await WebSocketTransformer.upgrade(request);
          await handleWebSocket(socket, user);
        } else {
          if (cors) {
            request.response.headers
              ..add("Access-Control-Allow-Origin", "*")
              ..add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
              ..add("Access-Control-Allow-Headers", "Content-Type, Authorization");
          }
          if (request.method == "OPTIONS") {
            await request.response.close();
          } else if (controllers.containsKey(request.uri.path)) {
            var controller = controllers[request.uri.path];
            Request req = Request();
            req.path = request.uri.path;
            Map<String, String> headers = {};
            request.headers.forEach((name, values) {
              headers[name] = values.first;
            });
            req.headers = headers;
            String body = await utf8.decoder.bind(request).join();
            req.data = jsonDecode(body);
            Response? res = await controller!(req);
            res ??= Response();
            String resStr = jsonEncode(res.toJson());
            request.response.write(resStr);
            await request.response.close();
            return;
          } else {
            await handleHttpRequest(request);
          }
        }
      });
    } catch (e) {
      logger ?? ('Error starting HTTP server: $e');
    }
  }

  Future<void> stop() async {
    status = ServerStatus.stopped;
    if (server != null) {
      await removeAllNode();
      await server!.close();
      logger ?? ('HTTP server stopped');
      server = null;
    }
  }

  Future<Response?> send(int hashCode, Request req) async {
    final node = nodes[hashCode];
    if (node == null) {
      return null;
    }
    return await node.send(req);
  }

  void broadcast(Request req) async {
    final futures = nodes.values.map((client) => client.send(req));
    await Future.wait(futures);
  }

  Future<void> handleWebSocket(WebSocket socket, User? user) async {
    final hashCode = socket.hashCode;
    await removeNode(hashCode);
    final node = Node(socket, user);
    if (user == null) {
      Request req = Request(path: Path.kick);
      node.send(req, true);
      node.stop();
      return;
    }
    addNode(hashCode, node);
    socket.listen(
      (message) async {
        try {
          final msg = Message.fromJson(jsonDecode(message));
          if (msg.type == MessageType.response) {
            node.receive(msg);
          } else if (msg.type == MessageType.request) {
            final req = msg.request!;
            req.headers[Header.wsHashCode.name] = hashCode.toString();
            responseHandler(controllers, msg, socket);
          }
        } catch (e) {
          logger ?? ('Error handling WebSocket message: $e');
        } finally {
          node.resetCloseTime();
        }
      },
      onDone: () {
        removeNode(hashCode);
        logger ?? ('Client disconnected: $hashCode');
      },
      onError: (error) {
        removeNode(hashCode);
        logger ?? ('Client disconnected: $hashCode. Error: $error');
      },
    );
  }

  Future<void> removeAllNode() async {
    for (final node in nodes.values) {
      await node.stop();
    }
    nodes.clear();
  }

  Future<void> removeNode(int hashCode) async {
    final n = nodes.remove(hashCode);
    await n?.stop();
  }

  void addNode(int hashCode, Node<User> node) {
    nodes[hashCode] = node;
    node.start();
  }
}
