import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/common/app_lifecycle.dart';

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

  void cancelTimer() {
    closeTimer?.cancel();
    closeTimer = null;
  }

  Future<void> stop() async {
    cancelTimer();
    await webSocket.close();
  }

  void start() {
    cancelTimer();
    closeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // App 在后台（锁屏、切走）时不判掉线：内嵌 WebView 里的 JS 被 Chromium 冻结，
      // 2s 心跳根本发不出来，这时候按 10s 静默把连接关掉纯属误杀，解锁回来就成了
      // "游戏服务连不上"。顺手把期限往后推，免得刚回前台的第一轮扫描又立刻判死。
      // 局域网上的学生端自己是前台跑着的，心跳照常，不受这条影响。
      if (AppLifecycle.background) {
        resetCloseTime();
        return;
      }
      if (closeTime.isBefore(DateTime.now())) {
        stop();
      }
    });
  }

  void resetCloseTime() {
    closeTime = DateTime.now().add(const Duration(seconds: 10));
    print('$hashCode:$closeTime');
  }
}
