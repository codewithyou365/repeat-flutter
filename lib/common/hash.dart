import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:async';

class Hash {
  static Future<String> toSha1(String filePath) async {
    var file = File(filePath);

    if (!await file.exists()) {
      return "";
    }

    var inputStream = file.openRead();
    final sha1Stream = sha1.bind(inputStream);

    var sha1Hash = await sha1Stream.first;

    return sha1Hash.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  static String toSha1ForString(String s) {
    final bytes = utf8.encode(s);
    final sha1Hash = sha1.convert(bytes);
    return sha1Hash.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
