class ContentArgs {
  String? bookName;
  Future<void> Function()? removeWarning;
  int? initLessonSelect;
  int defaultTap;
  int? selectSegmentKeyId;

  ContentArgs({
    this.bookName,
    this.initLessonSelect,
    this.selectSegmentKeyId,
    this.removeWarning,
    this.defaultTap = 0,
  });
}
