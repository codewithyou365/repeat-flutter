class ContentArgs {
  String? bookName;
  int? initChapterSelect;
  int defaultTap;
  int? selectVerseKeyId;
  bool enableEnteringRepeatView;

  ContentArgs({
    this.bookName,
    this.initChapterSelect,
    this.selectVerseKeyId,
    this.defaultTap = 0,
    this.enableEnteringRepeatView = false,
  });
}
