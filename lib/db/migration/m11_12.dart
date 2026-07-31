import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' show DatabaseExecutor;

/// 提示（'t'）从一块变成一个数组，一节可以挂好几条：
///
/// 旧：`{"t": {"text": "提示", "start": ..}}`
/// 新：`{"t": [{"text": "提示", "start": ..}]}`
///
/// book 那一层顺带把重载拆开。旧的 book 的 't' 块同时是「提示字体」和「提示服务配置
/// （按 'a'/'q'/'t'/'n' 分的子 map，写进 Tip 表）」：
///
/// 旧：`{"t": {"fontSize": "18", "q": {"h":..,"k":..}, "t": {"h":..}, "n": {..}}}`
/// 新：`{"q": {"h":..,"k":..}, "n": {..}, "t": [{"fontSize": "18", "h":..}]}`
///
/// 也就是每个字段块自己带着自己的字体和提示服务配置，'t' 的第 i 条连名字（'n'）一起
/// 放在 `t[i]` 里——这样提示的下标在 book/chapter/verse 三层是对齐的。
///
/// 这里的 key 全部写成字面量而不是引用 VerseField：迁移记录的是"当时的格式"，
/// 以后模型再改名也不能反过来改变这一版迁移的行为。
final m11_12 = Migration(11, 12, migrateTipToList);

/// 提示服务配置在旧 book 的 't' 块子 map 里用的几个 key。
const _tipConfigKeys = ['i', 'h', 'n', 'k', 's'];

Future<void> migrateTipToList(DatabaseExecutor database) async {
  for (var table in ['Verse', 'VerseContentVersion', 'Chapter', 'ChapterContentVersion']) {
    await _rewrite(database, table, migrateVerseContentTo12);
  }
  for (var table in ['Book', 'BookContentVersion']) {
    await _rewrite(database, table, migrateBookContentTo12);
  }
}

/// 整表读出来，在 Dart 里改完再写回去。
/// rowid 必须起别名：Verse 的 id 是 rowid 的别名，直接 `SELECT rowid` 拿回来的列名是 `id`，
/// 按 'rowid' 取会是 null，整个迁移会静默地什么都不做。
Future<void> _rewrite(
  DatabaseExecutor database,
  String table,
  String? Function(String) migrate,
) async {
  final rows = await database.rawQuery('SELECT rowid AS _rowid, content FROM `$table`');
  final batch = database.batch();
  var changed = 0;
  for (final row in rows) {
    final rowId = row['_rowid'];
    final content = row['content'];
    if (rowId == null || content is! String) {
      continue;
    }
    final ret = migrate(content);
    if (ret == null) {
      continue;
    }
    batch.rawUpdate('UPDATE `$table` SET content = ?1 WHERE rowid = ?2', [ret, rowId]);
    changed++;
  }
  if (changed > 0) {
    await batch.commit(noResult: true);
  }
}

Map<String, dynamic>? _decode(String content) {
  try {
    final decoded = jsonDecode(content);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// verse/chapter：把 't' 那一块包进数组。
/// 本来就是数组（或者没有 't'、内容坏了）就返回 null，表示这行不用动。
String? migrateVerseContentTo12(String content) {
  final map = _decode(content);
  if (map == null) {
    return null;
  }
  final t = map['t'];
  if (t is! Map<String, dynamic>) {
    return null;
  }
  map['t'] = t.isEmpty ? <dynamic>[] : <dynamic>[t];
  return jsonEncode(map);
}

/// book：拆重载——提示服务配置下放到各字段块，'t' 变成数组。
String? migrateBookContentTo12(String content) {
  final map = _decode(content);
  if (map == null) {
    return null;
  }
  final t = map['t'];
  if (t is! Map<String, dynamic>) {
    return null;
  }

  // 't' 里除了 'a'/'q'/'t'/'n' 四个子 map，剩下的就是提示自己的字体，跟着第 1 条走。
  final tipField = <String, dynamic>{};
  final subMaps = <String, Map<String, dynamic>>{};
  t.forEach((key, value) {
    if (const ['a', 'q', 't', 'n'].contains(key) && value is Map<String, dynamic>) {
      subMaps[key] = value;
      return;
    }
    tipField[key] = value;
  });

  for (final entry in subMaps.entries) {
    final config = <String, dynamic>{};
    for (final key in _tipConfigKeys) {
      final v = entry.value[key];
      if (v != null) {
        config[key] = v;
      }
    }
    if (config.isEmpty) {
      continue;
    }
    if (entry.key == 't') {
      // 提示自己的配置跟提示字体合到同一块里（都是第 1 条提示的）。
      tipField.addAll(config);
      continue;
    }
    // q/a/n 的配置并进它们本来就有的字体块。
    final field = map[entry.key];
    if (field is Map<String, dynamic>) {
      field.addAll(config);
    } else {
      map[entry.key] = config;
    }
  }

  map['t'] = tipField.isEmpty ? <dynamic>[] : <dynamic>[tipField];
  return jsonEncode(map);
}
