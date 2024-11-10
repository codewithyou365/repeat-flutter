import 'dart:io';

import 'dart:convert' as convert;

class RepeatDoc {
  String rootPath;
  String key;
  String rootUrl;
  List<Lesson> lesson;

  RepeatDoc(this.rootPath, this.key, this.rootUrl, this.lesson);

  static Future<bool> writeFile(String path, Map<String, dynamic> m) async {
    try {
      File file = File(path);
      String jsonString = convert.jsonEncode(m);
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> toJsonMap(String path) async {
    File file = File(path);
    bool exist = await file.exists();
    if (!exist) {
      return null;
    }
    String jsonString = await file.readAsString();
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    return jsonData;
  }

  static Future<RepeatDoc?> fromPath(String path, Uri defaultRootUri) async {
    Map<String, dynamic>? jsonData = await toJsonMap(path);
    return fromJsonAndUri(jsonData, defaultRootUri);
  }

  static RepeatDoc? fromJsonAndUri(Map<String, dynamic>? jsonData, Uri defaultRootUri) {
    if (jsonData == null) {
      return null;
    }
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

  Map<String, dynamic> toJson() {
    return {
      'rootPath': rootPath,
      'key': key,
      'rootUrl': rootUrl,
      'lesson': lesson,
    };
  }
}

class Lesson {
  String url;
  String path;
  String hash;
  String key;
  String defaultQuestion;
  String defaultTip;
  String title;
  String titleStart;
  String titleEnd;
  List<Segment> segment;

  Lesson(
    this.url,
    this.path,
    this.hash,
    this.key,
    this.defaultQuestion,
    this.defaultTip,
    this.title,
    this.titleStart,
    this.titleEnd,
    this.segment,
  );

  factory Lesson.fromJson(Map<String, dynamic> json) {
    var url = json['url'] ?? "";
    var path = "";
    if (url != "") {
      path = json['path'];
    }
    var defaultQuestion = json['defaultQuestion'] ?? '';
    var defaultTip = json['defaultTip'] ?? '';
    return Lesson(
      url,
      path,
      json['hash'] ?? '',
      json['key'] ?? json['path'],
      defaultQuestion,
      defaultTip,
      json['title'] ?? json['key'] ?? json['path'],
      json['titleStart'] ?? "00:00:00,000",
      json['titleEnd'] ?? "00:00:00,000",
      List<Segment>.from(json['segment'].map((dynamic s) => Segment.fromJson(
            s,
            json['segment'].indexOf(s),
            defaultQuestion,
            defaultTip,
          ))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'path': path,
      'hash': hash,
      'key': key,
      'defaultQuestion': defaultQuestion,
      'defaultTip': defaultTip,
      'title': title,
      'titleStart': titleStart,
      'titleEnd': titleEnd,
      'segment': segment,
    };
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

  factory Segment.fromJson(
    Map<String, dynamic> json,
    int index,
    String defaultQuestion,
    String defaultTip,
  ) {
    return Segment(
      json['key'] ?? (index + 1).toString(),
      json['tipStart'] ?? "",
      json['tipEnd'] ?? "",
      json['tip'] ?? defaultTip,
      json['qStart'] ?? "",
      json['qEnd'] ?? "",
      json['q'] ?? defaultQuestion,
      json['aStart'] ?? "",
      json['aEnd'] ?? "",
      json['a'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'tipStart': tipStart,
      'tipEnd': tipEnd,
      'tip': tip,
      'qStart': qStart,
      'qEnd': qEnd,
      'q': q,
      'aStart': aStart,
      'aEnd': aEnd,
      'a': a,
    };
  }
}
