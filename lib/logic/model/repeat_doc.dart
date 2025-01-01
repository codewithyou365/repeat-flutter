import 'dart:io';

import 'dart:convert' as convert;

import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class RepeatDoc {
  String rootUrl;
  List<Lesson> lesson;

  RepeatDoc(this.rootUrl, this.lesson);

  static Future<bool> writeFile(String path, Map<String, dynamic> m) async {
    try {
      var rootPath = await DocPath.getContentPath();
      File file = File(rootPath.joinPath(path));
      String jsonString = convert.jsonEncode(m);
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> toJsonString(String path) async {
    var rootPath = await DocPath.getContentPath();
    File file = File(rootPath.joinPath(path));
    bool exist = await file.exists();
    if (!exist) {
      return null;
    }
    return await file.readAsString();
  }

  static Future<Map<String, dynamic>?> toJsonMap(String path) async {
    String? jsonString = await toJsonString(path);
    if (jsonString == null) {
      return null;
    }
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    return jsonData;
  }

  static Future<RepeatDoc?> fromPath(String path, {Uri? rootUri}) async {
    Map<String, dynamic>? jsonData = await toJsonMap(path);
    return fromJsonAndUri(jsonData, rootUri);
  }

  static RepeatDoc? fromJsonAndUri(Map<String, dynamic>? jsonData, Uri? rootUri) {
    if (jsonData == null) {
      return null;
    }
    var kv = RepeatDoc.fromJson(jsonData);
    if (rootUri != null) {
      kv.rootUrl = "${rootUri.scheme}://${rootUri.host}:${rootUri.port}/${rootUri.pathSegments.sublist(0, rootUri.pathSegments.length - 1).join('/')}/";
    }
    return kv;
  }

  factory RepeatDoc.fromJson(Map<String, dynamic> json) {
    return RepeatDoc(
      json['rootUrl'] ?? "",
      List<Lesson>.from(json['lesson'].map((dynamic d) => Lesson.fromJson(d))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rootUrl': rootUrl,
      'lesson': lesson,
    };
  }
}

class Lesson {
  String url;
  String mediaExtension;
  String hash;
  String videoMaskRatio;
  String defaultQuestion;
  String defaultTip;
  String title;
  String titleStart;
  String titleEnd;
  List<Segment> segment;

  Lesson(
    this.url,
    this.mediaExtension,
    this.hash,
    this.videoMaskRatio,
    this.defaultQuestion,
    this.defaultTip,
    this.title,
    this.titleStart,
    this.titleEnd,
    this.segment,
  );

  factory Lesson.fromJson(Map<String, dynamic> json) {
    var url = json['url'] ?? '';
    var defaultQuestion = json['defaultQuestion'] ?? '';
    var defaultTip = json['defaultTip'] ?? '';
    return Lesson(
      url,
      json['mediaExtension'] ?? url.split('.').last,
      json['hash'] ?? '',
      json['videoMaskRatio'] ?? '',
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
      'hash': hash,
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
  String tipStart;
  String tipEnd;
  String tip;
  String qStart;
  String qEnd;
  String q;
  String aStart;
  String aEnd;
  String a;
  String w;

  Segment(
    this.tipStart,
    this.tipEnd,
    this.tip,
    this.qStart,
    this.qEnd,
    this.q,
    this.aStart,
    this.aEnd,
    this.a,
    this.w,
  );

  factory Segment.fromJson(
    Map<String, dynamic> json,
    int index,
    String defaultQuestion,
    String defaultTip,
  ) {
    return Segment(
      json['tipStart'] ?? "",
      json['tipEnd'] ?? "",
      json['tip'] ?? defaultTip,
      json['qStart'] ?? "",
      json['qEnd'] ?? "",
      json['q'] ?? defaultQuestion,
      json['aStart'] ?? "",
      json['aEnd'] ?? "",
      json['a'] ?? "",
      json['w'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipStart': tipStart,
      'tipEnd': tipEnd,
      'tip': tip,
      'qStart': qStart,
      'qEnd': qEnd,
      'q': q,
      'aStart': aStart,
      'aEnd': aEnd,
      'a': a,
      'w': w,
    };
  }
}
