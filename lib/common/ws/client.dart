import 'dart:convert';
import 'dart:io';

import 'message.dart';
import 'node.dart';

class Client {
  Logger? logger;

  Node? node;
  final Map<String, Controller> controllers = {};

  Future<Response?> send(Request req) async {
    if (node == null) {
      return null;
    }
    return await node!.send(req);
  }

  Future<bool> start(String url) async {
    if (node != null) {
      return false;
    }
    var socket = await WebSocket.connect(
      url,
    );
    node = Node(socket, null);
    socket.listen(
      (message) async {
        try {
          final msg = Message.fromJson(jsonDecode(message));
          if (msg.type == MessageType.response) {
            node?.receive(msg);
          } else if (msg.type == MessageType.request) {
            responseHandler(controllers, msg, socket);
          } else {
            logger?.call('Unknown message type: ${msg.type}');
          }
        } catch (e) {
          logger ?.call ('Error handling WebSocket message: $e');
        }
      },
      onDone: () {
        node = null;
        logger ?.call ('Client disconnected: ');
      },
      onError: (error) {
        node = null;
        logger ?.call ('Client disconnected: . Error: $error');
      },
    );
    return true;
  }

  void stop() {
    if (node != null) {
      node!.webSocket.close();
    }
  }
}
