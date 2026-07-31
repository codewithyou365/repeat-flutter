import 'dart:convert';
import 'dart:developer';

import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/search/verse_tokenizer.dart';

/// 材料全文检索的索引层。
///
/// FTS5 虚拟表用原生 SQL 建，不走 floor 的 entity，所以不需要 bump database
/// version、不需要写 migration。floor 不认识这张表，也不会去 drop 它。
class VerseSearchIndex {
  static const String table = 'VerseFts';
  static const int batchSize = 200;

  /// 老安卓的系统 SQLite 可能没启用 FTS5，建表失败时降级成内存 contains 搜索。
  static bool ftsAvailable = true;
  static bool _tableReady = false;

  /// 幂等建表。返回 false 表示这台设备用不了 FTS5。
  static Future<bool> ensureTable() async {
    if (_tableReady) {
      return ftsAvailable;
    }
    try {
      await Db().db.database.execute(
            'CREATE VIRTUAL TABLE IF NOT EXISTS $table USING fts5('
            'tokens'
            ',verseId UNINDEXED'
            ',classroomId UNINDEXED'
            ",tokenize = 'unicode61'"
            ')',
          );
      ftsAvailable = true;
    } catch (e) {
      log('VerseSearchIndex: fts5 unavailable, fallback to in-memory search. $e');
      ftsAvailable = false;
    }
    _tableReady = true;
    return ftsAvailable;
  }

  /// 整体指纹，覆盖增/删/改：contentVersion 每次内容更新会 +1，
  /// 导入/删除会改变 count 和 max(id)。
  static Future<String> fingerprint(int classroomId) async {
    var rows = await Db().db.database.rawQuery(
      'SELECT COUNT(1) c,IFNULL(SUM(contentVersion),0) v,IFNULL(MAX(id),0) m FROM Verse WHERE classroomId=?',
      [classroomId],
    );
    var row = rows.first;
    return '${VerseTokenizer.schemaVersion}:${row['c']}:${row['v']}:${row['m']}';
  }

  static Future<String?> savedFingerprint(int classroomId) {
    return Db().db.crKvDao.getStr(classroomId, CrK.searchIndexFingerprint);
  }

  /// 索引是否需要重建。
  static Future<bool> needRebuild(int classroomId) async {
    if (!ftsAvailable) {
      return false;
    }
    var saved = await savedFingerprint(classroomId);
    if (saved == null) {
      return true;
    }
    return saved != await fingerprint(classroomId);
  }

  /// 重建当前教室的索引。只清当前教室，切教室时不用互相重建。
  static Future<void> rebuild(
    int classroomId,
    List<VerseShow> verses, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (!await ensureTable()) {
      return;
    }
    var db = Db().db.database;
    await db.delete(table, where: 'classroomId = ?', whereArgs: [classroomId]);
    onProgress?.call(0, verses.length);
    for (var start = 0; start < verses.length; start += batchSize) {
      var end = start + batchSize;
      if (end > verses.length) {
        end = verses.length;
      }
      var batch = db.batch();
      for (var i = start; i < end; i++) {
        var verse = verses[i];
        var tokens = _toIndexText(verse);
        if (tokens.isEmpty) {
          continue;
        }
        batch.insert(table, {
          'tokens': tokens,
          'verseId': verse.verseId,
          'classroomId': classroomId,
        });
      }
      await batch.commit(noResult: true);
      onProgress?.call(end, verses.length);
      // 让出事件循环，进度条才能真的动
      await Future.delayed(Duration.zero);
    }
    await Db().db.crKvDao.insertOrReplace(CrKv(
      classroomId,
      CrK.searchIndexFingerprint,
      await fingerprint(classroomId),
    ));
  }

  /// 单条脏数据不能中断整轮建索引。
  static String _toIndexText(VerseShow verse) {
    try {
      var content = VerseContent.fromJson(jsonDecode(verse.verseContent));
      return VerseTokenizer.buildIndexText([
        content.key,
        content.write,
        content.note,
        // 一节可以挂好几条提示，每条都要能搜到。
        ...content.tips.map((e) => e.text),
        content.question,
        content.answer,
      ]);
    } catch (e) {
      log('VerseSearchIndex: skip verse ${verse.verseId}, bad content. $e');
      return '';
    }
  }

  /// 按相关度返回命中的 verseId。
  static Future<List<int>> search(int classroomId, String input, {int limit = 200}) async {
    if (!await ensureTable()) {
      return [];
    }
    var match = VerseTokenizer.buildMatchQuery(input);
    if (match == null) {
      return [];
    }
    var rows = await Db().db.database.rawQuery(
      'SELECT verseId FROM $table WHERE classroomId=? AND tokens MATCH ? ORDER BY bm25($table) LIMIT ?',
      [classroomId, match, limit],
    );
    return rows.map((e) => e['verseId'] as int).toList();
  }
}
