import 'dart:io';

import 'dart:convert' as convert;

import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class ZipRootDoc {
  List<Doc> docs;
  String url;

  ZipRootDoc(this.docs, this.url);

  static Future<ZipRootDoc?> fromPath(String path) async {
    File file = File(path);
    bool exist = await file.exists();
    if (!exist) {
      return null;
    }
    String jsonString = await file.readAsString();
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    return ZipRootDoc.fromJson(jsonData);
  }

  factory ZipRootDoc.fromJson(Map<String, dynamic> json) {
    return ZipRootDoc(
      (json['docs'] as List<dynamic>).map((docJson) => Doc.fromJson(docJson as Map<String, dynamic>)).toList(),
      json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docs': docs.map((doc) => doc.toJson()).toList(),
      'url': url,
    };
  }
}
