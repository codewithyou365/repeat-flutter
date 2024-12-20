import 'dart:convert';
import 'dart:io';

typedef Controller = Future<Response?> Function(Request req);

Future<void> responseHandler(
  Map<String, Controller> controllers,
  Message msg,
  WebSocket webSocket,
) async {
  Response? res;
  final req = msg.request!;
  final controller = controllers[req.path];
  if (controller != null) {
    try {
      res = await controller(msg.request!) ?? Response(status: 501);
    } catch (e) {
      res = Response(status: 500, error: e.toString());
    }
  } else {
    res = Response(status: 404);
  }
  final body = jsonEncode(
    Message(id: msg.id, type: MessageType.response, response: res).toJson(),
  );

  webSocket.add(body);
}

enum Header {
  wsHashCode,
}

enum MessageType {
  request,
  response,
}

class Message {
  MessageType type = MessageType.request;
  int id = 0;
  Request? request;
  Response? response;

  Message({
    this.type = MessageType.request,
    this.id = 0,
    this.request,
    this.response,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      type: MessageType.values[json['type'] ?? MessageType.request.index],
      id: json['id'] ?? 0,
      request: json['request'] != null ? Request.fromJson(json['request']) : null,
      response: json['response'] != null ? Response.fromJson(json['response']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'id': id,
      'request': request?.toJson(),
      'response': response?.toJson(),
    };
  }
}

class Request {
  String path = '';
  Map<String, String> headers = {};
  String data = '';

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
  String data = '';

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
