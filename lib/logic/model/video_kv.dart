import 'dart:io';

import 'dart:convert' as convert;

import 'repeat_content.dart';

class VideoKv extends RepeatContent {
  List<Video> data;

  VideoKv(String type, String rootPath, String rootUrl, this.data) : super(type, rootPath, rootUrl);

  static Future<VideoKv> fromFile(String path, Uri defaultRootUri) async {
    File file = File(path);
    String jsonString = await file.readAsString();
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    var kv = VideoKv.fromJson(jsonData);
    if (kv.rootUrl == "") {
      kv.rootUrl = "${defaultRootUri.scheme}://${defaultRootUri.host}:${defaultRootUri.port}";
    }
    if (kv.rootPath == "") {
      kv.rootPath = defaultRootUri.host;
    }
    return kv;
  }

  factory VideoKv.fromJson(Map<String, dynamic> json) {
    return VideoKv(
      json['type'],
      json['rootPath'] ?? "",
      json['rootUrl'] ?? "",
      List<Video>.from(json['data'].map((dynamic d) => Video.fromJson(d))),
    );
  }
}

class Video {
  String videoUrl;
  String videoPath;
  List<Split> split;

  Video(this.videoUrl, this.videoPath, this.split);

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      json['videoUrl'],
      json['videoPath'],
      List<Split>.from(json['split'].map((dynamic s) => Split.fromJson(s))),
    );
  }
}

class Split {
  String start;
  String end;
  String key;
  String value;

  Split(this.start, this.end, this.key, this.value);

  factory Split.fromJson(Map<String, dynamic> json) {
    return Split(
      json['start'],
      json['end'],
      json['key'],
      json['value'],
    );
  }
}
