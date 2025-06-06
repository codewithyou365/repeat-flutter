class ContentArgs {
  String? bookName;
  Future<void> Function()? removeWarning;
  int? initLessonSelect;
  int defaultTap;
  int? selectVerseKeyId;

  ContentArgs({
    this.bookName,
    this.initLessonSelect,
    this.selectVerseKeyId,
    this.removeWarning,
    this.defaultTap = 0,
  });
}
