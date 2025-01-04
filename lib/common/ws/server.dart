import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'node.dart';

import 'message.dart';

class Server<User> {
  final cors = true;
  Logger? logger;
  HttpServer? server;
  final Map<String, Controller> controllers = {};
  final Map<int, Node<User>> nodes = {};

  Future<void> start(int port, Future<User?> Function(HttpRequest request) auth, Future<void> Function(HttpRequest request) handleHttpRequest) async {
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, port);

      server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          User? user = await auth(request);
          if (user == null) {
            return;
          }
          WebSocket socket = await WebSocketTransformer.upgrade(request);
          handleWebSocket(socket, user);
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
    if (server != null) {
      await server!.close();
      nodes.clear();
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

  void handleWebSocket(WebSocket socket, User user) {
    final hashCode = socket.hashCode;
    final node = Node(socket, user);
    nodes[hashCode] = node;
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
        }
      },
      onDone: () {
        nodes.remove(hashCode);
        logger ?? ('Client disconnected: $hashCode');
      },
      onError: (error) {
        nodes.remove(hashCode);
        logger ?? ('Client disconnected: $hashCode. Error: $error');
      },
    );
  }
}
