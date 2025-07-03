import 'package:flutter/cupertino.dart';

class AwaitUtil {
  static var lock = false;

  static bool tryDo(Future<void> Function() callback) {
    if (lock) {
      return false;
    }
    lock = true;
    try {
      callback().then((_) {
        lock = false;
      });
    } finally {
      lock = false;
    }

    return true;
  }
}
