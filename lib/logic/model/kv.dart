import 'dart:io';

import 'dart:convert' as convert;

import 'repeat_content.dart';

class Kv extends RepeatContent {
  List<Data> data;

  Kv(String type, String rootPath, String rootUrl, this.data) : super(type, rootPath, rootUrl);

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
      List<Data>.from(json['data'].map((dynamic d) => Data.fromJson(d))),
    );
  }
}

class Data {
  String url;
  String path;
  String index;
  List<Split> split;

  Data(this.url, this.path, this.index, this.split);

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      json['url'],
      json['path'],
      json['index'] ?? json['path'],
      List<Split>.from(json['split'].map((dynamic s) => Split.fromJson(s, json['split'].indexOf(s)))),
    );
  }
}

class Split {
  String start;
  String end;
  String index;
  String key;
  String value;

  Split(this.start, this.end, this.index, this.key, this.value);

  factory Split.fromJson(Map<String, dynamic> json, int index) {
    return Split(
      json['start'],
      json['end'],
      json['index'] ?? index.toString(),
      json['key'],
      json['value'],
    );
  }
}
