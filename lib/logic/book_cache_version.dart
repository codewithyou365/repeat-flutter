/// 网络编辑器的乐观锁版本号。
///
/// **不是数据缓存**：这里只存一个自增的整数，用来判断「浏览器上打开的那份书本文档，
/// 是不是在编辑期间被 App 这边改过了」。书本内容有任何变更（导入/重导入/删除/改内容/
/// 改章节/改句子），[ScCrLogic] 都会通过 EventBus 把对应 bookId 的版本号 +1；
/// 提交时版本号对不上就拒绝，见 [Commit] 和 [BookHandler]。
///
/// 以前它和三份全课堂的全量数据缓存挤在同一个 CacheHelp 里，那三份已经删掉了 ——
/// 别再往这个类里塞数据缓存。
class BookCacheVersion {
  static Map<int, int> bookId2CacheVersion = {};

  static void inc(int bookId) {
    bookId2CacheVersion[bookId] = (bookId2CacheVersion[bookId] ?? 0) + 1;
  }

  static int get(int bookId) {
    return bookId2CacheVersion[bookId] ?? 0;
  }
}
