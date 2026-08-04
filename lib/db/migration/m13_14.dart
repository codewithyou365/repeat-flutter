import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' show DatabaseExecutor;

/// 整节媒体从"位置约定"改成"显式引用"：给每一层内容补上 'm'。
///
/// 旧规矩：整节媒体 = verse -> chapter -> book 里第一个有 'd' 的那一层，取 'd' 的第一项。
/// 这是**整层覆盖**的——一节自己长出 'd'（比如扩展助手给某个字段生成的音频要登记文件对象），
/// 就会把章节的整节媒体连同后面几项一起遮蔽掉，整节突然没媒体可播。
///
/// 新规矩：整节媒体的 hash 写在顶层的 'm' 上（跟 's' 并排：'s' 说怎么显示，'m' 说是哪个文件）。
/// 'm' 仍然按 verse -> chapter -> book 就近取，但拿到 hash 之后是**跨所有层**去 'd' 里找文件对象，
/// 所以 verse 有没有自己的 'd' 都不影响它继承章节的整节媒体。
///
/// 这一版只是把旧规矩固化下来：每一层有 'd' 就补 'm' = 'd' 第一项的 hash，
/// 补完之后就近取 'm' 跟原来就近取 'd' 落在同一个文件上，行为完全不变。
///
/// 幂等：已经有 'm' 的行跳过，所以重复执行没有副作用。
///
/// key 全部写成字面量而不是引用 VerseField：迁移记录的是"当时的格式"，
/// 以后模型再改名也不能反过来改变这一版迁移的行为。
final m13_14 = Migration(13, 14, migrateSectionMediaHash);

Future<void> migrateSectionMediaHash(DatabaseExecutor database) async {
  // Book 的主键列名跟其它几张表不一样，单独列出来。
  const tables = <String, String>{
    'Book': 'id',
    'BookContentVersion': 'rowid',
    'Chapter': 'rowid',
    'ChapterContentVersion': 'rowid',
    'Verse': 'rowid',
    'VerseContentVersion': 'rowid',
  };

  for (final entry in tables.entries) {
    final table = entry.key;
    final idColumn = entry.value;
    // rowid 必须起别名：Verse/Chapter 的 id 是 rowid 的别名，直接 `SELECT rowid`
    // 拿回来的列名是 `id`，按 'rowid' 取会是 null，整个迁移会静默地什么都不做。
    final rows = await database.rawQuery('SELECT $idColumn AS _rowid, content FROM `$table`');
    final batch = database.batch();
    var changed = 0;
    for (final row in rows) {
      final rowId = row['_rowid'];
      final content = row['content'];
      if (rowId == null || content is! String) {
        continue;
      }
      final ret = migrateContentTo14(content);
      if (ret == null) {
        continue;
      }
      batch.rawUpdate('UPDATE `$table` SET content = ?1 WHERE $idColumn = ?2', [ret, rowId]);
      changed++;
    }
    if (changed > 0) {
      await batch.commit(noResult: true);
    }
  }
}

/// 本来就有 'm'、没有 'd'、或者内容坏了都返回 null，表示这行不用动。
String? migrateContentTo14(String content) {
  Map<String, dynamic> map;
  try {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    map = decoded;
  } catch (_) {
    return null;
  }

  if (map['m'] is String) {
    return null;
  }
  final list = map['d'];
  if (list is! List || list.isEmpty) {
    return null;
  }
  final first = list.first;
  if (first is! Map || first['h'] is! String) {
    return null;
  }
  map['m'] = first['h'];
  return jsonEncode(map);
}
