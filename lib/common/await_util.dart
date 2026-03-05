class AwaitUtil {
  static var lock = false;

  static Future<bool> tryDo(Future<void> Function() callback) async {
    if (lock) return false;
    lock = true;

    try {
      await callback();
      return true;
    } catch (e) {
      rethrow;
    } finally {
      lock = false;
    }
  }
}