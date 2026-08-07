import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/model/book_brief.dart';

/// 书名的取数口子。**故意不做全局缓存** —— 调用方在自己的生命周期里持有结果，
/// 页面关掉就跟着释放。一个课堂几本到几十本书，几 KB 而已。
///
/// 这里读一次所有 Book 行只是为了解析书名（书名不是数据库列，存在 content 的
/// 'n' 里，minSdk 24 没有 JSON1 扩展所以 SQL 查不了），解析完 content 就丢掉。
class BookBriefHelp {
  static Future<List<BookBrief>> load(int classroomId) async {
    var books = await Db().db.bookDao.getAll(classroomId);
    return books
        .where((e) => e.id != null)
        .map((e) => BookBrief(bookId: e.id!, name: e.name, sort: e.sort))
        .toList();
  }

  /// 只要 enable 的书本，和 getAllBook / getAllVerse 的口径一致。
  static Future<List<BookBrief>> loadEnabled(int classroomId) async {
    var books = await Db().db.bookDao.getByEnable(classroomId, true);
    return books
        .where((e) => e.id != null)
        .map((e) => BookBrief(bookId: e.id!, name: e.name, sort: e.sort))
        .toList();
  }

  static Future<Map<int, String>> loadNameMap(int classroomId) async {
    var books = await load(classroomId);
    return {for (var book in books) book.bookId: book.name};
  }
}
