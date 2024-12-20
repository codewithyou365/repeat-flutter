import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:repeat/common/ws/message.dart';

class Node {
  int sendId = 0;
  final Map<int, Completer<Response>> sendId2Res = {};
  WebSocket webSocket;

  Node(
    this.webSocket,
  );

  void receive(Message msg) {
    final future = sendId2Res.remove(msg.id);
    future?.complete(msg.response);
  }

  Future<Response?> send(Request req) async {
    var msg = jsonEncode(Message(id: ++sendId, type: MessageType.request, request: req).toJson());
    webSocket.add(msg);

    final completer = Completer<Response>();
    sendId2Res[sendId] = completer;

    final timer = Timer(Duration(seconds: 10), () {
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
}
