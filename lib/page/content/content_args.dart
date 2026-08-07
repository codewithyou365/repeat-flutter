class ContentArgs {
  /// 用 id 定位书本，不用书名 —— 书名会重名、会被改。
  int? bookId;
  int? initChapterSelect;
  int defaultTap;
  int? selectVerseKeyId;
  bool enableEnteringRepeatView;

  ContentArgs({
    this.bookId,
    this.initChapterSelect,
    this.selectVerseKeyId,
    this.defaultTap = 0,
    this.enableEnteringRepeatView = false,
  });
}
