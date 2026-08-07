import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';

/// 章节列表的过滤条件。和 [VerseFilter] 一样，条件全部下推 SQL。
class ChapterFilter {
  final int classroomId;

  /// null = 全部书本
  final int? bookId;

  /// null = 全部章节；只在 [bookId] 非空时有意义
  final int? chapterIndex;

  final String? keyword;

  /// true = 按位置升序，false = 降序
  final bool asc;

  const ChapterFilter({
    required this.classroomId,
    this.bookId,
    this.chapterIndex,
    this.keyword,
    this.asc = true,
  });
}

class ChapterQuery {
  static const String _showColumns = 'SELECT Chapter.id chapterId'
      ',Book.id bookId'
      ',Book.sort bookSort'
      ',Chapter.content chapterContent'
      ',Chapter.contentVersion chapterContentVersion'
      ',Chapter.chapterIndex';

  static const String _from = ' FROM Chapter'
      ' JOIN Book ON Book.id=Chapter.bookId AND Book.enable=true';

  static (String, List<Object?>) _where(ChapterFilter f) {
    var sql = StringBuffer(' WHERE Chapter.classroomId=?');
    var args = <Object?>[f.classroomId];
    if (f.bookId != null) {
      sql.write(' AND Chapter.bookId=?');
      args.add(f.bookId);
      if (f.chapterIndex != null) {
        sql.write(' AND Chapter.chapterIndex=?');
        args.add(f.chapterIndex);
      }
    }
    var keyword = f.keyword;
    if (keyword != null && keyword.isNotEmpty) {
      // 和以前内存里的 chapterContent.contains(kw) 一样，对原始 JSON 串匹配
      var escaped = keyword.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
      sql.write(" AND Chapter.content LIKE ? ESCAPE '\\'");
      args.add('%$escaped%');
    }
    return (sql.toString(), args);
  }

  static String _orderBy(bool asc) {
    return asc ? ' ORDER BY Book.sort,Chapter.chapterIndex' : ' ORDER BY Book.sort DESC,Chapter.chapterIndex DESC';
  }

  static Future<List<int>> queryIds(ChapterFilter f) async {
    var (where, args) = _where(f);
    var rows = await Db().db.database.rawQuery(
      'SELECT Chapter.id id$_from$where${_orderBy(f.asc)}',
      args,
    );
    return rows.map((e) => e['id'] as int).toList();
  }

  static Future<List<ChapterShow>> byIds(List<int> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    var rows = await Db().db.database.rawQuery(
      '$_showColumns$_from WHERE Chapter.id IN (${List.filled(ids.length, '?').join(',')})',
      ids,
    );
    return rows.map(_toShow).toList();
  }

  /// 每本书有哪几章 —— 只取两个 int，用来搭筛选下拉框，不碰 content。
  static Future<Map<int, List<int>>> chapterIndexesByBook(int classroomId) async {
    var rows = await Db().db.database.rawQuery(
      'SELECT Chapter.bookId bookId,Chapter.chapterIndex chapterIndex'
      '$_from WHERE Chapter.classroomId=? ORDER BY Book.sort,Chapter.chapterIndex',
      [classroomId],
    );
    var ret = <int, List<int>>{};
    for (var row in rows) {
      ret.putIfAbsent(row['bookId'] as int, () => []).add(row['chapterIndex'] as int);
    }
    return ret;
  }

  static ChapterShow _toShow(Map<String, Object?> row) {
    return ChapterShow(
      chapterId: row['chapterId'] as int,
      bookId: row['bookId'] as int,
      bookSort: row['bookSort'] as int,
      chapterContent: row['chapterContent'] as String,
      chapterContentVersion: row['chapterContentVersion'] as int,
      chapterIndex: row['chapterIndex'] as int,
    );
  }
}
