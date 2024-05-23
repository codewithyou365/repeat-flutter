import 'dart:io';

import 'dart:convert' as convert;


class RepeatDoc {
  String rootPath;
  String key;
  String rootUrl;
  List<Lesson> lesson;

  RepeatDoc(this.rootPath, this.key, this.rootUrl, this.lesson);

  static Future<RepeatDoc?> fromPath(String path, Uri defaultRootUri) async {
    File file = File(path);
    bool exist = await file.exists();
    if (!exist) {
      return null;
    }
    String jsonString = await file.readAsString();
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    var kv = RepeatDoc.fromJson(jsonData);
    if (kv.rootUrl == "") {
      kv.rootUrl = "${defaultRootUri.scheme}://${defaultRootUri.host}:${defaultRootUri.port}/${defaultRootUri.pathSegments.sublist(0, defaultRootUri.pathSegments.length - 1).join('/')}/";
    }
    if (kv.rootPath == "") {
      kv.rootPath = defaultRootUri.host;
    }
    return kv;
  }

  factory RepeatDoc.fromJson(Map<String, dynamic> json) {
    return RepeatDoc(
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
  String title;
  List<Segment> segment;

  Lesson(this.url, this.path, this.key, this.title, this.segment);

  factory Lesson.fromJson(Map<String, dynamic> json) {
    var url = json['url'] ?? "";
    var path = "";
    if (url != "") {
      path = json['path'];
    }
    return Lesson(
      url,
      path,
      json['key'] ?? json['path'],
      json['title'] ?? json['key'] ?? json['path'],
      List<Segment>.from(json['segment'].map((dynamic s) => Segment.fromJson(s, json['segment'].indexOf(s)))),
    );
  }
}

class Segment {
  String start;
  String end;
  String key;
  String q;
  String tip;
  String a;

  Segment(this.start, this.end, this.key, this.q, this.tip, this.a);

  factory Segment.fromJson(Map<String, dynamic> json, int index) {
    return Segment(
      json['start'] ?? "",
      json['end'] ?? "",
      json['key'] ?? index.toString(),
      json['q'],
      json['tip'] ?? "",
      json['a'],
    );
  }
}
