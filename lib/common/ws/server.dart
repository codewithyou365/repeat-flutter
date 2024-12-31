import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'node.dart';

import 'message.dart';

class Server {
  Logger? logger;
  HttpServer? server;
  final Map<String, Controller> controllers = {};
  final Map<int, Node> nodes = {};

  Future<void> start(int port, Future<void> Function(HttpRequest request) handleHttpRequest) async {
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, port);

      server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocket socket = await WebSocketTransformer.upgrade(request);
          handleWebSocket(socket);
        } else {
          await handleHttpRequest(request);
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

  void handleWebSocket(WebSocket socket) {
    final hashCode = socket.hashCode;
    final node = Node(socket);
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
