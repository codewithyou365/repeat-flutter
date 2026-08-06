import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_review.dart';
import 'package:repeat_flutter/logic/book_help.dart';

@Entity(tableName: "")
class VerseReviewWithKey extends VerseReview {
  @primaryKey
  int chapterIndex;
  int verseIndex;

  VerseReviewWithKey({
    required super.createDate,
    required super.verseId,
    required super.classroomId,
    required super.bookId,
    required super.chapterId,
    required super.count,
    required this.chapterIndex,
    required this.verseIndex,
  });

  /// 书名不是数据库列了，JOIN 不出来，按 bookId 从书本缓存里查
  String get contentName => BookHelp.getCache(bookId)?.name ?? '';
}
