import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:repeat/common/ws/node.dart';

import 'message.dart';
import 'package:repeat/widget/snackbar/snackbar.dart';

class Server {
  HttpServer? server;
  final Map<String, Controller> controllers = {};
  final Map<int, Node> nodes = {};

  Future<void> start(int port) async {
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      server!.transform(WebSocketTransformer()).listen(handleWebSocket);
    } catch (e) {
      Snackbar.show('Error starting HTTP server: $e');
    }
  }

  Future<void> stop() async {
    if (server != null) {
      await server!.close();
      nodes.clear();
      Snackbar.show('HTTP server stopped');
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
          Snackbar.show('Error handling WebSocket message: $e');
        }
      },
      onDone: () {
        nodes.remove(hashCode);
        Snackbar.show('Client disconnected: $hashCode');
      },
      onError: (error) {
        nodes.remove(hashCode);
        Snackbar.show('Client disconnected: $hashCode. Error: $error');
      },
    );
  }
}
