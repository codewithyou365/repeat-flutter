import 'book_help.dart';
import 'chapter_help.dart';
import 'verse_help.dart';

class CacheHelp {
  static Future<void> refresh() async {
    await BookHelp.tryGen(force: true);
    await ChapterHelp.tryGen(force: true);
    await VerseHelp.tryGen(force: true);
  }
}
