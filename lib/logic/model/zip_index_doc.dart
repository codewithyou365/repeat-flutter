import 'dart:io';

import 'dart:convert' as convert;

class ZipRootDoc {
  String url;

  ZipRootDoc(this.url);

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
      json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}
