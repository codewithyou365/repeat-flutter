import 'dart:io';

import 'dart:convert' as convert;

import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/logic/base/constant.dart';


class ZipIndexDoc {
  String file;
  String url;

  ZipIndexDoc(this.file, this.url);

  static Future<ZipIndexDoc?> fromPath() async {
    var path = await DocPath.getZipIndexFilePath();
    File file = File(path);
    bool exist = await file.exists();
    if (!exist) {
      return null;
    }
    String jsonString = await file.readAsString();
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    return ZipIndexDoc.fromJson(jsonData);
  }

  factory ZipIndexDoc.fromJson(Map<String, dynamic> json) {
    String url = json['url'];
    String urlFileName = Url.toDocName(url);
    return ZipIndexDoc(
      json['file'] ?? urlFileName,
      json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'url': url,
    };
  }
}
