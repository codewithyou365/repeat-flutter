import 'dart:convert';
import 'dart:io';

typedef Logger = void Function(String msg);

typedef Controller = Future<Response?> Function(Request req);
typedef Convert = Future<dynamic> Function(String req);

Future<void> responseHandler(
  Map<String, Controller> controllers,
  Message msg,
  WebSocket webSocket,
) async {
  Response? res;
  final req = msg.request!;
  req.headers[Header.age.name] = msg.age.toString();
  final controller = controllers[req.path];
  if (controller != null) {
    try {
      res = await controller(req) ?? Response(status: 501);
    } catch (e) {
      print(e.toString());
      res = Response(status: 500, error: e.toString());
    }
  } else {
    res = Response(status: 404);
  }
  final body = jsonEncode(
    Message(id: msg.id, age: msg.age, type: MessageType.response, response: res).toJson(),
  );

  webSocket.add(body);
}

enum Header {
  wsHashCode,
  age,
}

enum MessageType {
  request,
  response,
}

class Message {
  MessageType type = MessageType.request;
  int id = 0;
  int age = 0;
  Request? request;
  Response? response;

  Message({
    this.type = MessageType.request,
    this.id = 0,
    this.age = 0,
    this.request,
    this.response,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      type: MessageType.values[json['type'] ?? MessageType.request.index],
      id: json['id'] ?? 0,
      age: json['age'] ?? 0,
      request: json['request'] != null ? Request.fromJson(json['request']) : null,
      response: json['response'] != null ? Response.fromJson(json['response']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'id': id,
      'age': age,
      'request': request?.toJson(),
      'response': response?.toJson(),
    };
  }
}

class Request {
  String path = '';
  Map<String, String> headers = {};
  dynamic data = '';

  Request({
    this.path = '',
    this.headers = const {},
    this.data = '',
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      path: json['path'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      data: json['data'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'headers': headers,
      'data': data,
    };
  }
}

class Response {
  Map<String, String> headers = {};
  dynamic data = '';

  String error = '';
  int status = 200;

  Response({
    this.headers = const {},
    this.data = '',
    this.error = '',
    this.status = 200,
  });

  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      headers: Map<String, String>.from(json['headers'] ?? {}),
      data: json['data'] ?? '',
      error: json['error'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headers': headers,
      'data': data,
      'error': error,
      'status': status,
    };
  }
}
