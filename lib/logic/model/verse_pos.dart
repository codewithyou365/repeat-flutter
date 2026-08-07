/// 位置串（"书名-章-句"）只给界面看。
///
/// 以前这几个串是 VerseShow/ChapterShow 上的 getter，内部去全局书本缓存查书名，
/// 等于让数据模型依赖一份常驻内存。现在书名由调用方从自己持有的 bookName 表传进来，
/// **程序内部一律用 bookId 判断，不要拿这里的串去做比较或分组。**
String chapterPos(String bookName, int chapterIndex) {
  return '$bookName-${chapterIndex + 1}';
}

String versePos(String bookName, int chapterIndex, int verseIndex) {
  return '${chapterPos(bookName, chapterIndex)}-${verseIndex + 1}';
}
