import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/model/verse_brief.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';

/// 内容页句子列表的排序方式，和界面上那 6 个选项一一对应。
enum VerseSortBy {
  positionAsc,
  positionDesc,
  progressAsc,
  progressDesc,
  learnDateAsc,
  learnDateDesc,
}

/// 句子列表的过滤条件。所有条件都下推 SQL，不在内存里 where。
class VerseFilter {
  final int classroomId;

  /// null = 全部书本
  final int? bookId;

  /// null = 全部章节；只在 [bookId] 非空时有意义
  final int? chapterIndex;

  /// null = 不按进度过滤
  final int? progress;

  /// 下次学习的年月（Date.value 的前 4 位，即 yyyyMM）。null = 不过滤
  final int? learnMonth;

  /// 关键词命中的 verseId 集合（FTS 或 LIKE 的结果）。
  /// null = 没有关键词；空列表 = 有关键词但一条都没命中。
  final List<int>? verseIds;

  final VerseSortBy sortBy;

  const VerseFilter({
    required this.classroomId,
    this.bookId,
    this.chapterIndex,
    this.progress,
    this.learnMonth,
    this.verseIds,
    this.sortBy = VerseSortBy.positionAsc,
  });
}

/// 句子列表的查询层。
///
/// Floor 的 @Query 是静态 SQL，撑不住"书本 + 章节 + 进度 + 学习月份 + 6 种排序"
/// 的组合，所以这里手拼 SQL 走 rawQuery（[VerseSearchIndex] 也是这个路子）。
/// 参数一律走占位符，不要往 SQL 里拼用户输入。
class VerseQuery {
  /// 和 ScheduleDao.getAllVerse 保持同一套列，[VerseShow] 才接得住。
  static const String _showColumns = 'SELECT Verse.id verseId'
      ',Book.id bookId'
      ',Book.sort bookSort'
      ',Verse.content verseContent'
      ',Verse.contentVersion verseContentVersion'
      ',Verse.chapterId'
      ',Verse.chapterIndex'
      ',Verse.verseIndex'
      ',Verse.learnDate'
      ',Verse.progress';

  static const String _from = ' FROM Verse'
      ' JOIN Book ON Book.id=Verse.bookId AND Book.enable=true';

  /// 排序都追加 Verse.sort 兜底：进度/日期会大量相等，没有稳定序的话
  /// 分页取窗口会出现重复行和丢行。
  static String _orderBy(VerseSortBy sortBy) {
    switch (sortBy) {
      case VerseSortBy.positionAsc:
        return ' ORDER BY Verse.sort';
      case VerseSortBy.positionDesc:
        return ' ORDER BY Verse.sort DESC';
      case VerseSortBy.progressAsc:
        return ' ORDER BY Verse.progress,Verse.sort';
      case VerseSortBy.progressDesc:
        return ' ORDER BY Verse.progress DESC,Verse.sort';
      case VerseSortBy.learnDateAsc:
        return ' ORDER BY Verse.learnDate,Verse.sort';
      case VerseSortBy.learnDateDesc:
        return ' ORDER BY Verse.learnDate DESC,Verse.sort';
    }
  }

  static (String, List<Object?>) _where(VerseFilter f) {
    var sql = StringBuffer(' WHERE Verse.classroomId=?');
    var args = <Object?>[f.classroomId];
    if (f.bookId != null) {
      sql.write(' AND Verse.bookId=?');
      args.add(f.bookId);
      if (f.chapterIndex != null) {
        sql.write(' AND Verse.chapterIndex=?');
        args.add(f.chapterIndex);
      }
    }
    if (f.progress != null) {
      sql.write(' AND Verse.progress=?');
      args.add(f.progress);
    }
    if (f.learnMonth != null) {
      // 和原来的内存过滤保持一致：min < learnDate < max，两端开区间
      var min = f.learnMonth! * 100;
      sql.write(' AND Verse.learnDate>? AND Verse.learnDate<?');
      args.add(min);
      args.add(min + 99);
    }
    var ids = f.verseIds;
    if (ids != null) {
      if (ids.isEmpty) {
        // 有关键词但一条都没命中，直接返回空集
        sql.write(' AND 0');
      } else {
        sql.write(' AND Verse.id IN (${List.filled(ids.length, '?').join(',')})');
        args.addAll(ids);
      }
    }
    return (sql.toString(), args);
  }

  /// 按当前过滤 + 排序，取出全部命中的 verseId。
  ///
  /// 只取 id，一条 8 字节，十万条也就几百 KB —— 拿它当列表骨架（itemCount、
  /// scrollTo 的下标），正文再按滚动窗口去 [byIds] 取。
  static Future<List<int>> queryIds(VerseFilter f) async {
    var (where, args) = _where(f);
    var rows = await Db().db.database.rawQuery(
      'SELECT Verse.id id$_from$where${_orderBy(f.sortBy)}',
      args,
    );
    return rows.map((e) => e['id'] as int).toList();
  }

  static Future<int> count(VerseFilter f) async {
    var (where, args) = _where(f);
    var rows = await Db().db.database.rawQuery(
      'SELECT COUNT(1) c$_from$where',
      args,
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  static Future<List<VerseShow>> queryPage(
    VerseFilter f, {
    required int offset,
    required int limit,
  }) async {
    var (where, args) = _where(f);
    var rows = await Db().db.database.rawQuery(
      '$_showColumns$_from$where${_orderBy(f.sortBy)} LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );
    return rows.map(_toShow).toList();
  }

  /// 按 id 批量取正文，给滚动窗口用。返回顺序不保证，调用方按 id 建索引。
  static Future<List<VerseShow>> byIds(List<int> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    var rows = await Db().db.database.rawQuery(
      '$_showColumns$_from WHERE Verse.id IN (${List.filled(ids.length, '?').join(',')})',
      ids,
    );
    return rows.map(_toShow).toList();
  }

  /// 按 id 取轻量投影（不带正文），**按传入的 id 顺序返回**。
  /// 给 LazyVerseTodayPrgList 用：那是播放顺序，SQL 的 IN 不保证顺序。
  static Future<List<VerseBrief>> briefByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    var rows = await Db().db.database.rawQuery(
      'SELECT Verse.id verseId'
      ',Book.id bookId'
      ',Book.sort bookSort'
      ',Verse.chapterId'
      ',Verse.chapterIndex'
      ',Verse.verseIndex'
      '$_from WHERE Verse.id IN (${List.filled(ids.length, '?').join(',')})',
      ids,
    );
    var byId = {
      for (var row in rows)
        row['verseId'] as int: VerseBrief(
          verseId: row['verseId'] as int,
          bookId: row['bookId'] as int,
          bookSort: row['bookSort'] as int,
          chapterId: row['chapterId'] as int,
          chapterIndex: row['chapterIndex'] as int,
          verseIndex: row['verseIndex'] as int,
        )
    };
    return [
      for (var id in ids)
        if (byId[id] != null) byId[id]!
    ];
  }

  /// 筛选下拉框里"进度"有哪几档。让 SQL 去 DISTINCT，别为了列几个数把全课堂拉进内存。
  static Future<List<int>> distinctProgress(int classroomId) async {
    var rows = await Db().db.database.rawQuery(
      'SELECT DISTINCT Verse.progress p$_from WHERE Verse.classroomId=? ORDER BY Verse.progress',
      [classroomId],
    );
    return rows.map((e) => e['p'] as int).toList();
  }

  /// 筛选下拉框里"下次学习"有哪几个月（yyyyMM）。
  static Future<List<int>> distinctLearnMonth(int classroomId) async {
    var rows = await Db().db.database.rawQuery(
      'SELECT DISTINCT Verse.learnDate/100 m$_from WHERE Verse.classroomId=? ORDER BY m',
      [classroomId],
    );
    return rows.map((e) => e['m'] as int).toList();
  }

  /// 关键词的 SQL 降级路径：FTS5 用不了时走这里。
  /// 和以前内存里的 `verseContent.contains(kw)` 一样是对原始 JSON 串做匹配，行为等价。
  static Future<List<int>> searchIdsByLike(int classroomId, String keyword) async {
    var escaped = keyword.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
    var rows = await Db().db.database.rawQuery(
      'SELECT Verse.id id$_from'
      " WHERE Verse.classroomId=? AND Verse.content LIKE ? ESCAPE '\\'",
      [classroomId, '%$escaped%'],
    );
    return rows.map((e) => e['id'] as int).toList();
  }

  static VerseShow _toShow(Map<String, Object?> row) {
    return VerseShow(
      verseId: row['verseId'] as int,
      bookId: row['bookId'] as int,
      bookSort: row['bookSort'] as int,
      verseContent: row['verseContent'] as String,
      verseContentVersion: row['verseContentVersion'] as int,
      chapterId: row['chapterId'] as int,
      chapterIndex: row['chapterIndex'] as int,
      verseIndex: row['verseIndex'] as int,
      learnDate: Date(row['learnDate'] as int),
      progress: row['progress'] as int,
    );
  }
}
