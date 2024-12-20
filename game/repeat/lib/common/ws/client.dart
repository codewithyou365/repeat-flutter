import 'dart:convert';
import 'dart:io';

import 'package:repeat/common/ws/message.dart';
import 'package:repeat/common/ws/node.dart';
import 'package:repeat/widget/snackbar/snackbar.dart';

class Client {
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
    node = Node(socket);
    socket.listen(
      (message) async {
        try {
          final msg = Message.fromJson(jsonDecode(message));
          if (msg.type == MessageType.response) {
            node?.receive(msg);
          } else if (msg.type == MessageType.request) {
            responseHandler(controllers, msg, socket);
          } else {
            Snackbar.show('Unknown message type: ${msg.type}');
          }
        } catch (e) {
          Snackbar.show('Error handling WebSocket message: $e');
        }
      },
      onDone: () {
        node = null;
        Snackbar.show('Client disconnected: ');
      },
      onError: (error) {
        node = null;
        Snackbar.show('Client disconnected: . Error: $error');
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
