class ContentArgs {
  String? bookName;
  Future<void> Function()? removeWarning;
  int? initChapterSelect;
  int defaultTap;
  int? selectVerseKeyId;

  ContentArgs({
    this.bookName,
    this.initChapterSelect,
    this.selectVerseKeyId,
    this.removeWarning,
    this.defaultTap = 0,
  });
}
