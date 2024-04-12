import 'dart:io';

import 'dart:convert' as convert;

import 'repeat_content.dart';

class Kv extends RepeatContent {
  List<Lesson> lesson;

  Kv(String type, String rootPath, String rootUrl, this.lesson) : super(type, rootPath, rootUrl);

  static Future<Kv> fromFile(String path, Uri defaultRootUri) async {
    File file = File(path);
    String jsonString = await file.readAsString();
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    var kv = Kv.fromJson(jsonData);
    if (kv.rootUrl == "") {
      kv.rootUrl = "${defaultRootUri.scheme}://${defaultRootUri.host}:${defaultRootUri.port}";
    }
    if (kv.rootPath == "") {
      kv.rootPath = defaultRootUri.host;
    }
    return kv;
  }

  factory Kv.fromJson(Map<String, dynamic> json) {
    return Kv(
      json['type'],
      json['rootPath'] ?? "",
      json['rootUrl'] ?? "",
      List<Lesson>.from(json['lesson'].map((dynamic d) => Lesson.fromJson(d))),
    );
  }
}

class Lesson {
  String url;
  String path;
  String index;
  List<Segment> segment;

  Lesson(this.url, this.path, this.index, this.segment);

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      json['url'],
      json['path'],
      json['index'] ?? json['path'],
      List<Segment>.from(json['segment'].map((dynamic s) => Segment.fromJson(s, json['segment'].indexOf(s)))),
    );
  }
}

class Segment {
  String start;
  String end;
  String index;
  String key;
  String value;

  Segment(this.start, this.end, this.index, this.key, this.value);

  factory Segment.fromJson(Map<String, dynamic> json, int index) {
    return Segment(
      json['start'],
      json['end'],
      json['index'] ?? index.toString(),
      json['key'],
      json['value'],
    );
  }
}
