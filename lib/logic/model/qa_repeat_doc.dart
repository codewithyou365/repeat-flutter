import 'dart:io';

import 'dart:convert' as convert;

import 'repeat_doc.dart';

class QaRepeatDoc extends RepeatDoc {
  List<Lesson> lesson;

  QaRepeatDoc(String type, String rootPath, String key, String rootUrl, this.lesson) : super(type, rootPath, key, rootUrl);

  static Future<QaRepeatDoc> fromPath(String path, Uri defaultRootUri) async {
    File file = File(path);
    String jsonString = await file.readAsString();
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    var kv = QaRepeatDoc.fromJson(jsonData);
    if (kv.rootUrl == "") {
      kv.rootUrl = "${defaultRootUri.scheme}://${defaultRootUri.host}:${defaultRootUri.port}";
    }
    if (kv.rootPath == "") {
      kv.rootPath = defaultRootUri.host;
    }
    return kv;
  }

  factory QaRepeatDoc.fromJson(Map<String, dynamic> json) {
    return QaRepeatDoc(
      json['type'],
      json['rootPath'] ?? "",
      json['key'] ?? json['rootPath'] ?? "",
      json['rootUrl'] ?? "",
      List<Lesson>.from(json['lesson'].map((dynamic d) => Lesson.fromJson(d))),
    );
  }
}

class Lesson {
  String url;
  String path;
  String key;
  List<Segment> segment;

  Lesson(this.url, this.path, this.key, this.segment);

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      json['url'],
      json['path'],
      json['key'] ?? json['path'],
      List<Segment>.from(json['segment'].map((dynamic s) => Segment.fromJson(s, json['segment'].indexOf(s)))),
    );
  }
}

class Segment {
  String start;
  String end;
  String key;
  String q;
  String a;

  Segment(this.start, this.end, this.key, this.q, this.a);

  factory Segment.fromJson(Map<String, dynamic> json, int index) {
    return Segment(
      json['start'],
      json['end'],
      json['key'] ?? index.toString(),
      json['q'],
      json['a'],
    );
  }
}
