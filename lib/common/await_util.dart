import 'package:flutter/cupertino.dart';

class AwaitUtil {
  static var lock = false;

  static bool tryDo(Future<void> Function() callback) {
    if (lock) {
      return false;
    }
    lock = true;
    callback().then((_) {
      lock = false;
    });
    return true;
  }
}
