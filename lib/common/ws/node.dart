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
  DateTime closeTime = DateTime.now();

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

  cancelTimer() {
    closeTimer?.cancel();
    closeTimer = null;
  }

  stop() async {
    print('${this.hashCode}:stop');
    final stackTrace = StackTrace.current;
    print('Calling stack: $stackTrace');
    cancelTimer();
    await webSocket.close();
  }

  void start() {
    cancelTimer();
    closeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (closeTime.isBefore(DateTime.now())) {
        stop();
      }
    });
  }

  resetCloseTime() {
    closeTime = DateTime.now().add(const Duration(seconds: 10));
    print('${this.hashCode}:$closeTime');
  }
}
