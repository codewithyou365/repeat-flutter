import 'dart:ui';

import 'package:repeat_flutter/logic/model/book_show.dart';

class BookEditorArgs {
  int? chapterIndex;
  int? verseIndex;
  BookShow bookShow;

  BookEditorArgs({
    required this.bookShow,
    this.chapterIndex,
    this.verseIndex,
  });
}
