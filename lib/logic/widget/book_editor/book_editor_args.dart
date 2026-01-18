import 'dart:ui';

import 'package:repeat_flutter/logic/model/book_show.dart';

class BookEditorArgs {
  int chapterIndex;
  int verseIndex;
  int bookId;

  BookEditorArgs({
    required this.bookId,
    required this.chapterIndex,
    required this.verseIndex,
  });
}
