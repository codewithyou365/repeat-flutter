class ContentArgs {
  String? bookName;
  Future<void> Function()? removeWarning;
  int? initChapterSelect;
  int defaultTap;
  int? selectVerseKeyId;
  bool enableEnteringRepeatView;

  ContentArgs({
    this.bookName,
    this.initChapterSelect,
    this.selectVerseKeyId,
    this.removeWarning,
    this.defaultTap = 0,
    this.enableEnteringRepeatView = false,
  });
}
