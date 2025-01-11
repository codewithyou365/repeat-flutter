import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'message.dart';

class Node<User> {
  int sendId = 0;
  User? user;
  final Map<int, Completer<Response>> sendId2Res = {};
  final WebSocket webSocket;
  Timer? closeTimer;

  Node(
    this.webSocket,
    this.user,
  );

  void receive(Message msg) {
    final future = sendId2Res.remove(msg.id);
    future?.complete(msg.response);
  }

  Future<Response?> send(Request req, [bool withoutRes = false]) async {
    var msg = jsonEncode(Message(id: ++sendId, type: MessageType.request, request: req).toJson());
    webSocket.add(msg);
    if (withoutRes) {
      return null;
    }
    final completer = Completer<Response>();
    sendId2Res[sendId] = completer;

    final timer = Timer(const Duration(seconds: 10), () {
      if (sendId2Res.remove(sendId) == completer) {
        completer.complete(Response(error: 'timeout', status: 504));
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      sendId2Res.remove(sendId);
    }
  }

  tryCloseAfterTimeout() {
    closeTimer?.cancel();
    closeTimer = Timer(const Duration(seconds: 10), () {
      webSocket.close();
    });
  }
}
