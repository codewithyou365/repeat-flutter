import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';

class BookFilter {
  final int classroomId;

  /// null = 全部书本
  final int? bookId;
  final String? keyword;

  /// true = 按位置升序，false = 降序
  final bool asc;

  const BookFilter({
    required this.classroomId,
    this.bookId,
    this.keyword,
    this.asc = true,
  });
}

/// 书本列表的查询层。书本数量不多，但每本的 content 可能挺大（'d' 下载列表），
/// 所以正文一样走窗口按需取，不整份常驻。
class BookQuery {
  static const String _showColumns = 'SELECT id bookId'
      ',classroomId'
      ',sort'
      ',content bookContent'
      ',contentVersion bookContentVersion';

  static (String, List<Object?>) _where(BookFilter f) {
    var sql = StringBuffer(' WHERE classroomId=? AND enable=true');
    var args = <Object?>[f.classroomId];
    if (f.bookId != null) {
      sql.write(' AND id=?');
      args.add(f.bookId);
    }
    var keyword = f.keyword;
    if (keyword != null && keyword.isNotEmpty) {
      // 和以前内存里的 bookContent.contains(kw) 一样，对原始 JSON 串匹配
      var escaped = keyword.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
      sql.write(" AND content LIKE ? ESCAPE '\\'");
      args.add('%$escaped%');
    }
    return (sql.toString(), args);
  }

  static Future<List<int>> queryIds(BookFilter f) async {
    var (where, args) = _where(f);
    var rows = await Db().db.database.rawQuery(
      'SELECT id FROM Book$where ORDER BY sort${f.asc ? '' : ' DESC'}',
      args,
    );
    return rows.map((e) => e['id'] as int).toList();
  }

  static Future<List<BookShow>> byIds(List<int> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    var rows = await Db().db.database.rawQuery(
      '$_showColumns FROM Book WHERE id IN (${List.filled(ids.length, '?').join(',')})',
      ids,
    );
    return rows.map(_toShow).toList();
  }

  static BookShow _toShow(Map<String, Object?> row) {
    return BookShow(
      bookId: row['bookId'] as int,
      classroomId: row['classroomId'] as int,
      sort: row['sort'] as int,
      bookContent: row['bookContent'] as String,
      bookContentVersion: row['bookContentVersion'] as int,
    );
  }
}
