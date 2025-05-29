import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';

import 'model/book_show.dart';

class BookHelp {
  static List<BookShow> cache = [];
  static Map<int, BookShow> bookIdToShow = {};

  static tryGen({force = false}) async {
    if (cache.isEmpty || force) {
      cache = await Db().db.contentDao.getAllBook(Classroom.curr);
      bookIdToShow = {for (var book in cache) book.bookId: book};
    }
  }

  static Future<List<BookShow>> getBooks({force = false}) async {
    await tryGen(force: force);
    return cache;
  }

  static BookShow? getCache(int bookId) {
    return BookHelp.bookIdToShow[bookId];
  }

  static void deleteCache(int bookId) {
    cache.removeWhere((element) => element.bookId == bookId);
    bookIdToShow.remove(bookId);
  }
}
