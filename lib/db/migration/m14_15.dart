import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' show DatabaseExecutor;

/// 自定义动作的指令从"选出来"改成"自己写"。
///
/// 旧规矩：sourceIndex 选一个来源字段（问题/答案/提示1..8），templateIndex 指向
/// classroom KV（CrKv 的 copyTemplate）里模版库的第几条，执行时把来源字段的正文塞进
/// 那条模版的 {{text}} 里渲染；参数个数单独存在 inputCount 上。
///
/// 新规矩：模版原文直接存在动作自己身上（template 列），里面用 {{question}}/{{answer}}/
/// {{tip1}}..{{tip8}} 引用本节字段，{{input1}}..{{input10}} 是执行前填的参数；
/// 参数个数按模版里出现的最大 inputN 推出来，不再存库。
///
/// 所以这一版要把老动作的模版**原文**从模版库里捞出来落到 template 上，并把里面的
/// {{text}} 换成它当时选的那个来源字段的占位符。模版库拿不到/下标越界的，模版留空
/// （用户下次编辑动作时重写一遍）。
///
/// SQLite 删不掉列，且 floor 要求表结构跟 database.g.dart 生成的 DDL 一模一样，
/// 所以走"建新表 -> 逐行回填 -> 删旧表 -> 改名 -> 重建索引"。
///
/// key/表名全部写成字面量而不是引用模型：迁移记录的是"当时的格式"，
/// 以后模型再改名也不能反过来改变这一版迁移的行为。
final m14_15 = Migration(14, 15, migrateActionTemplate);

Future<void> migrateActionTemplate(DatabaseExecutor database) async {
  final rows = await database.rawQuery(
    'SELECT `id`, `classroomId`, `name`, `sourceIndex`, `templateIndex`, `targetIndex`, `enableAudio`, `behavior`, `sort` FROM `AssistiveTouchAction`',
  );

  // 模版库是按教室存的，同一个教室只读一次。
  final templatesByClassroom = <int, List<String>>{};
  Future<List<String>> templatesOf(int classroomId) async {
    final cached = templatesByClassroom[classroomId];
    if (cached != null) {
      return cached;
    }
    var ret = <String>[];
    final kv = await database.rawQuery(
      'SELECT `value` FROM `CrKv` WHERE `classroomId` = ?1 AND `k` = ?2',
      [classroomId, 'copyTemplate'],
    );
    if (kv.isNotEmpty) {
      final value = kv.first['value'];
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            ret = decoded.whereType<String>().toList();
          }
        } catch (_) {}
      }
    }
    templatesByClassroom[classroomId] = ret;
    return ret;
  }

  final migrated = <List<Object?>>[];
  for (final row in rows) {
    final classroomId = row['classroomId'] as int? ?? 0;
    final templateIndex = row['templateIndex'] as int? ?? 0;
    final sourceIndex = row['sourceIndex'] as int? ?? 0;
    final templates = await templatesOf(classroomId);
    var template = '';
    if (templateIndex >= 0 && templateIndex < templates.length) {
      template = replaceTextPlaceholder(templates[templateIndex], sourceIndex);
    }
    migrated.add([
      row['id'],
      classroomId,
      row['name'] ?? '',
      template,
      row['targetIndex'] ?? 0,
      row['enableAudio'] ?? 0,
      row['behavior'] ?? 0,
      row['sort'] ?? 0,
    ]);
  }

  await database.execute('DROP TABLE IF EXISTS `AssistiveTouchActionNew`');
  await database.execute(
    'CREATE TABLE IF NOT EXISTS `AssistiveTouchActionNew` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `name` TEXT NOT NULL, `template` TEXT NOT NULL, `targetIndex` INTEGER NOT NULL, `enableAudio` INTEGER NOT NULL, `behavior` INTEGER NOT NULL, `sort` INTEGER NOT NULL)',
  );
  if (migrated.isNotEmpty) {
    final batch = database.batch();
    for (final values in migrated) {
      batch.rawInsert(
        'INSERT INTO `AssistiveTouchActionNew` (`id`, `classroomId`, `name`, `template`, `targetIndex`, `enableAudio`, `behavior`, `sort`) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)',
        values,
      );
    }
    await batch.commit(noResult: true);
  }
  await database.execute('DROP TABLE `AssistiveTouchAction`');
  await database.execute('ALTER TABLE `AssistiveTouchActionNew` RENAME TO `AssistiveTouchAction`');
  await database.execute('CREATE INDEX IF NOT EXISTS `index_AssistiveTouchAction_classroomId` ON `AssistiveTouchAction` (`classroomId`)');
}

/// 把模版原文里的 {{text}} 换成旧 sourceIndex 对应的占位符。
/// sourceIndex：0=问题、1=答案、2=老的"提示"（当第 1 条）、3 起是第 n-2 条提示。
String replaceTextPlaceholder(String template, int sourceIndex) {
  String placeholder;
  if (sourceIndex == 0) {
    placeholder = '{{question}}';
  } else if (sourceIndex == 1) {
    placeholder = '{{answer}}';
  } else if (sourceIndex <= 2) {
    placeholder = '{{tip1}}';
  } else {
    // 3 -> tip1、4 -> tip2……最多 8 条。
    var tip = sourceIndex - 2;
    if (tip > 8) {
      tip = 8;
    }
    placeholder = '{{tip$tip}}';
  }
  return template.replaceAll(RegExp(r'\{\{\s*text\s*\}\}'), placeholder);
}
