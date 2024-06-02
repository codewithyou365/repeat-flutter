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
  String titleStart;
  String titleEnd;
  List<Segment> segment;

  Lesson(this.url, this.path, this.key, this.title, this.titleStart, this.titleEnd, this.segment);

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
      json['titleStart'] ?? "00:00:00,000",
      json['titleEnd'] ?? "00:00:00,000",
      List<Segment>.from(json['segment'].map((dynamic s) => Segment.fromJson(s, json['segment'].indexOf(s)))),
    );
  }
}

class Segment {
  String key;
  String tipStart;
  String tipEnd;
  String tip;
  String qStart;
  String qEnd;
  String q;
  String aStart;
  String aEnd;
  String a;

  Segment(
    this.key,
    this.tipStart,
    this.tipEnd,
    this.tip,
    this.qStart,
    this.qEnd,
    this.q,
    this.aStart,
    this.aEnd,
    this.a,
  );

  factory Segment.fromJson(Map<String, dynamic> json, int index) {
    return Segment(
      json['key'] ?? (index + 1).toString(),
      json['tipStart'] ?? "",
      json['tipEnd'] ?? "",
      json['tip'] ?? "",
      json['qStart'] ?? "",
      json['qEnd'] ?? "",
      json['q'] ?? "",
      json['aStart'] ?? "",
      json['aEnd'] ?? "",
      json['a'],
    );
  }
}
