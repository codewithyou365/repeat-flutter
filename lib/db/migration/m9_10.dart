import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' show DatabaseExecutor;

/// verse 内容里 q/a/t 三个字段的平铺 key 改成一个嵌套块：
///
/// 旧：`{"a": "答案", "aStart": .., "aEnd": .., "aDownload": {"u":..,"h":..}, "aShowType": ..}`
/// 新：`{"a": {"text": "答案", "start": .., "end": .., "mediaHash": "..", "showType": ..}}`
///
/// 字段专属媒体的文件对象不再挂在字段里，统一进 'd' 列表（跟字体一样，字段块里只留 hash）：
/// 这一节本来就有 'd' 就追加到 verse 的 'd'，否则登记到 book 的 'd'——在原本没有 'd' 的
/// verse 上凭空造一个 'd'，会把这一节的整节媒体顶成这个文件。
///
/// 笔记（'n'）没有媒体和区间，正文仍然平铺，不动。
///
/// 只迁 verse 这一层：字段专属媒体/区间从来只写在小节上，book 的 't' 是提示配置、
/// chapter 里也没有这些 key，动了反而会把提示配置改坏。
///
/// 这里的 key 全部写成字面量而不是引用 VerseField：迁移记录的是"当时的格式"，
/// 以后模型再改名也不能反过来改变这一版迁移的行为。
final m9_10 = Migration(9, 10, migrateFieldBlocks);

/// 把 verse 内容里的字段信息统一成字段块 + 'd' 里的文件对象。
/// 幂等：已经是新格式的行直接跳过，所以可以在多版迁移里重复执行。
Future<void> migrateFieldBlocks(DatabaseExecutor database) async {
  // bookId -> 需要登记到这本书 'd' 里的文件对象（按 hash 去重）
  final bookMedia = <int, Map<String, Map<String, dynamic>>>{};

  for (var table in ['Verse', 'VerseContentVersion']) {
    // 先整表读出来，在 Dart 里改完再写回去。
    // rowid 必须起别名：Verse 的 id 是 rowid 的别名，直接 `SELECT rowid` 拿回来的列名是 `id`，
    // 按 'rowid' 取会是 null，整个迁移会静默地什么都不做。
    final rows = await database.rawQuery('SELECT rowid AS _rowid, bookId, content FROM `$table`');
    final batch = database.batch();
    var changed = 0;
    for (final row in rows) {
      final rowId = row['_rowid'];
      final content = row['content'];
      if (rowId == null || content is! String) {
        continue;
      }
      final ret = migrateVerseContentTo10(content);
      if (ret == null) {
        continue;
      }
      final bookId = row['bookId'];
      if (bookId is int) {
        for (final d in ret.bookMedia) {
          final hash = d['h'];
          if (hash is String) {
            (bookMedia[bookId] ??= {})[hash] = d;
          }
        }
      }
      batch.rawUpdate('UPDATE `$table` SET content = ?1 WHERE rowid = ?2', [ret.content, rowId]);
      changed++;
    }
    if (changed > 0) {
      await batch.commit(noResult: true);
    }
  }

  // 那些没地方放的文件对象，登记到所属 book 的 'd' 里。
  for (final entry in bookMedia.entries) {
    final rows = await database.rawQuery('SELECT content FROM `Book` WHERE id = ?1', [entry.key]);
    if (rows.isEmpty) {
      continue;
    }
    final content = rows.first['content'];
    if (content is! String) {
      continue;
    }
    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      map = decoded;
    } catch (_) {
      continue;
    }
    final list = map['d'] is List ? List<dynamic>.from(map['d'] as List) : <dynamic>[];
    final existing = <String>{};
    for (final d in list) {
      if (d is Map && d['h'] is String) {
        existing.add(d['h'] as String);
      }
    }
    var added = false;
    for (final d in entry.value.values) {
      if (existing.add(d['h'] as String)) {
        list.add(d);
        added = true;
      }
    }
    if (!added) {
      continue;
    }
    map['d'] = list;
    await database.rawUpdate('UPDATE `Book` SET content = ?1 WHERE id = ?2', [jsonEncode(map), entry.key]);
  }
}

class VerseMigrationTo10 {
  /// 改写后的 JSON。
  final String content;

  /// 这一节放不下的字段媒体文件对象，要由调用方登记到所属 book 的 'd' 里。
  final List<Map<String, dynamic>> bookMedia;

  VerseMigrationTo10(this.content, this.bookMedia);
}

/// 本来就是新格式（或者内容坏了）就返回 null，表示这行不用动。
VerseMigrationTo10? migrateVerseContentTo10(String content) {
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

  var changed = false;
  final bookMedia = <Map<String, dynamic>>[];

  // 这一节自己有 'd' 才往里追加：没有 'd' 的节，凭空造一个会把整节媒体顶掉，
  // 这种就交给调用方登记到 book 上。
  final own = map['d'] is List ? map['d'] as List : null;

  for (final acronym in ['q', 'a', 't']) {
    final field = <String, dynamic>{};

    // 已经是新格式的块（可能是这一版之后又编辑过的）先保留，再把还没搬的平铺 key 并进来。
    final curr = map[acronym];
    if (curr is Map<String, dynamic>) {
      field.addAll(curr);
    } else if (curr is String && curr.isNotEmpty) {
      field['text'] = curr;
      changed = true;
    }

    void move(String oldKey, String newKey) {
      if (!map.containsKey(oldKey)) {
        return;
      }
      final value = map.remove(oldKey);
      changed = true;
      if (field.containsKey(newKey)) {
        return;
      }
      if (value == null || (value is String && value.isEmpty)) {
        return;
      }
      field[newKey] = value;
    }

    move('${acronym}Start', 'start');
    move('${acronym}End', 'end');
    move('${acronym}ShowType', 'showType');
    // 字幕导入的提示以前写在 'tip' 上，而全 App 读的是 't'，等于一直没显示。
    // 这一版顺手归位到 t 的正文。
    if (acronym == 't') {
      move('tip', 'text');
    }

    // 文件对象搬进 'd'，字段块里只留 hash。
    // 'aDownload' 是最早的平铺写法；字段块里内嵌的 'download' 是中途那一版的写法，一并收掉。
    var d = map.remove('${acronym}Download');
    if (d == null && field['download'] != null) {
      d = field.remove('download');
    } else {
      field.remove('download');
    }
    if (d != null) {
      changed = true;
      if (d is Map<String, dynamic> && d['h'] is String && !field.containsKey('mediaHash')) {
        field['mediaHash'] = d['h'];
        if (own != null) {
          if (!own.any((e) => e is Map && e['h'] == d['h'])) {
            own.add(d);
          }
        } else {
          bookMedia.add(d);
        }
      }
    }

    if (field.isEmpty) {
      map.remove(acronym);
    } else {
      map[acronym] = field;
    }
  }

  if (!changed) {
    return null;
  }
  return VerseMigrationTo10(jsonEncode(map), bookMedia);
}
