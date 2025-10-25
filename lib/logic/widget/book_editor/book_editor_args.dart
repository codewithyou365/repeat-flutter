import 'dart:ui';

import 'package:repeat_flutter/logic/model/book_show.dart';

class BookEditorArgs {
  int? chapterIndex;
  int? verseIndex;
  int bookId;
  String bookName;

  BookEditorArgs({
    required this.bookId,
    required this.bookName,
    this.chapterIndex,
    this.verseIndex,
  });
}
