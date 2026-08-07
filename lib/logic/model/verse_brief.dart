import 'package:floor/floor.dart';

/// 句子的轻量投影：**不带 content**。
///
/// 只需要定位和排序的场景（全局浏览、今日计划列表）用它。
/// 别图省事换成 [VerseShow] —— 那个带着整条正文，整个课堂拉下来就是内存大头。
@Entity(tableName: "")
class VerseBrief {
  @primaryKey
  final int verseId;
  final int bookId;
  final int bookSort;
  final int chapterId;
  final int chapterIndex;
  final int verseIndex;

  VerseBrief({
    required this.verseId,
    required this.bookId,
    required this.bookSort,
    required this.chapterId,
    required this.chapterIndex,
    required this.verseIndex,
  });

  int toSort() {
    return verseSortOf(bookSort, chapterIndex, verseIndex);
  }
}

/// Verse.sort 的编码方式：把「第几本-第几章-第几句」压成一个可比较的整数。
/// 4611686118427387904-(99999*10000000000+99999*100000+99999)
int verseSortOf(int bookSort, int chapterIndex, int verseIndex) {
  return bookSort * 10000000000 + chapterIndex * 100000 + verseIndex;
}
