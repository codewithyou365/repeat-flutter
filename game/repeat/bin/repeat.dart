import 'dart:convert';

import 'package:repeat/common/ws/client.dart';
import 'package:repeat/common/ws/message.dart';
import 'package:repeat/common/ws/server.dart';
import 'dart:isolate';

void main() async {
  final receivePort = ReceivePort();
  Server s = Server();
  s.start(8089);
  await Isolate.spawn(worker, [receivePort.sendPort]);
}

void worker(List args) async {
  Client client = Client();
  await client.start("ws://127.0.0.1:8089");
  var count = 0;
  while (true) {
    count++;
    Request request = Request(data: "hello");
    print("request: ${jsonEncode(request.toJson())}");
    var response = await client.send(request);
    print("response: ${jsonEncode(response?.toJson())}");
    print("");
    if (count == 5) {
      client.stop();
    }
    if (count == 10) {
      client.start("ws://127.0.0.1:8089");
    }
    await Future.delayed(Duration(seconds: 1));
  }
}
