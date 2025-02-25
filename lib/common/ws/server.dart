import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/logic/game_server/constant.dart';

import 'node.dart';

import 'message.dart';

abstract class UserId {
  int getId();
}

enum ServerStatus {
  stopped,
  working,
}

class Nodes<User extends UserId> {
  final Map<int, Node<User>> hashCode2Node = {};
  final Map<int, Node<User>> userId2Node = {};

  Future<void> removeAll() async {
    for (final node in hashCode2Node.values) {
      await node.stop();
    }
    hashCode2Node.clear();
    userId2Node.clear();
  }

  Future<void> remove(int hashCode) async {
    final node = hashCode2Node.remove(hashCode);
    if (node != null) {
      int userId = node.user!.getId();
      userId2Node.remove(userId);
      await node.stop();
    }
  }

  Future<void> add(int hashCode, Node<User> node) async {
    var userId = node.user!.getId();
    var oldNode = userId2Node[userId];
    if (oldNode != null) {
      await remove(oldNode.webSocket.hashCode);
    }
    hashCode2Node[hashCode] = node;
    userId2Node[node.user!.getId()] = node;
    node.start();
  }

  Node<User>? get(int hashCode) {
    return hashCode2Node[hashCode];
  }

  Future<Response?> send(int hashCode, Request req) async {
    final node = hashCode2Node[hashCode];
    if (node == null) {
      return null;
    }
    return await node.send(req);
  }

  Future<void> broadcast(Request req) async {
    final futures = hashCode2Node.values.map((client) => client.send(req));
    await Future.wait(futures);
  }
}

class Server<User extends UserId> {
  final cors = true;
  var status = ServerStatus.working;
  Logger? logger;
  HttpServer? server;
  final Map<String, Controller> controllers = {};
  final Nodes<User> nodes = Nodes();

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
      logger?.call('Error starting HTTP server: $e');
    }
  }

  Future<void> stop() async {
    status = ServerStatus.stopped;
    if (server != null) {
      await nodes.removeAll();
      await server!.close();
      logger?.call('HTTP server stopped');
      server = null;
    }
  }

  Future<Response?> send(int hashCode, Request req) async {
    return nodes.send(hashCode, req);
  }

  Future<void> broadcast(Request req) async {
    return nodes.broadcast(req);
  }

  Future<void> handleWebSocket(WebSocket socket, User? user) async {
    final hashCode = socket.hashCode;
    final node = Node(socket, user);
    if (user == null) {
      Request req = Request(path: Path.kick);
      node.send(req, true);
      node.stop();
      return;
    }
    await nodes.add(hashCode, node);
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
          logger?.call('Error handling WebSocket message: $e');
        } finally {
          node.resetCloseTime();
        }
      },
      onDone: () {
        nodes.remove(hashCode);
        logger?.call('Client disconnected: $hashCode');
      },
      onError: (error) {
        nodes.remove(hashCode);
        logger?.call('Client disconnected: $hashCode. Error: $error');
      },
    );
  }
}
