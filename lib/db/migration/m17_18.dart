import 'dart:convert' as convert;
import 'dart:io';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// 游戏从"挂在某一本书下面"改成"整个课堂全局"。
///
/// - 宣告：每本书 content 的 'g' 搬进课堂 content 的 'g'，它引用的 zip 也从书本的 'd'
///   搬进课堂的 'd'（按 hash 去重）。
/// - 文件：zip 从 c/<课堂>/<书本>/<hh>/<xxx>.<ext> 搬到 c/<课堂>/g/<hh>/<xxx>.<ext>，
///   老的解压目录直接删掉，下次 ClassroomHelp.registerRes 会在新位置重新解压。
///   'g' 这个目录名不会跟书本目录（纯数字）撞上。
/// - 表：Game 去掉 bookId 列。SQLite 到 3.35 才有 DROP COLUMN，minSdk 24 的机器上没有，
///   所以整表重建；id 保留不变，课堂内容里游戏的 'i' 才还指得回来，游戏存档 data 也不丢。
///
/// 最后把 CrKv 里的 classroomResourceVersion 删掉，逼 registerRes 重新登记一遍。
final m17_18 = Migration(17, 18, (database) async {
  final contentRoot = '${await sqflite.getDatabasesPath()}/c';

  Map<String, dynamic> decodeMap(Object? raw) {
    final text = (raw as String?) ?? '';
    if (text.isEmpty) return <String, dynamic>{};
    try {
      final decoded = convert.jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  // DownloadContent 的路径规则：文件夹取 hash 前两位，文件名是剩下的 hash + 扩展名
  String folderOf(String hash) => hash.substring(0, 2);
  String pureNameOf(String hash) => hash.substring(2);
  String fileNameOf(String hash, String url) => '${pureNameOf(hash)}.${url.split('.').last}';

  final classrooms = await database.rawQuery('SELECT `id`,`content` FROM `Classroom`');
  for (final classroom in classrooms) {
    final classroomId = classroom['id'] as int;
    final classroomMap = decodeMap(classroom['content']);
    final classroomGames = (classroomMap['g'] as List?)?.toList() ?? <dynamic>[];
    final classroomDownloads = (classroomMap['d'] as List?)?.toList() ?? <dynamic>[];
    final classroomHashes = classroomDownloads.whereType<Map>().map((e) => e['h'] as String?).whereType<String>().toSet();
    var classroomChanged = false;

    final books = await database.rawQuery(
      'SELECT `id`,`content` FROM `Book` WHERE `classroomId`=?',
      [classroomId],
    );
    for (final book in books) {
      final bookId = book['id'] as int;
      final bookMap = decodeMap(book['content']);
      final games = (bookMap['g'] as List?) ?? const [];
      if (games.isEmpty) {
        continue;
      }
      final bookDownloads = (bookMap['d'] as List?) ?? <dynamic>[];

      for (final game in games) {
        if (game is! Map) continue;
        classroomGames.add(game);

        final hash = game['h'] as String?;
        if (hash == null || hash.length < 3) continue;

        final download = bookDownloads.whereType<Map>().firstWhere(
              (e) => e['h'] == hash,
              orElse: () => <String, dynamic>{},
            );
        if (download.isEmpty) continue;

        if (classroomHashes.add(hash)) {
          classroomDownloads.add(download);
        }
        bookDownloads.removeWhere((e) => e is Map && e['h'] == hash);

        // 文件搬家：zip 挪过去，老的解压目录删掉
        final url = (download['u'] as String?) ?? '.zip';
        final folder = folderOf(hash);
        final fileName = fileNameOf(hash, url);
        final from = File('$contentRoot/$classroomId/$bookId/$folder/$fileName');
        if (await from.exists()) {
          final toDir = Directory('$contentRoot/$classroomId/g/$folder');
          if (!await toDir.exists()) {
            await toDir.create(recursive: true);
          }
          final to = '${toDir.path}/$fileName';
          try {
            await from.rename(to);
          } catch (e) {
            await from.copy(to);
            await from.delete();
          }
        }
        final unzipped = Directory('$contentRoot/$classroomId/$bookId/$folder/${pureNameOf(hash)}');
        if (await unzipped.exists()) {
          await unzipped.delete(recursive: true);
        }
      }

      bookMap.remove('g');
      bookMap['d'] = bookDownloads;
      await database.rawUpdate(
        'UPDATE `Book` SET `content`=? WHERE `id`=?',
        [convert.jsonEncode(bookMap), bookId],
      );
      classroomChanged = true;
    }

    if (classroomChanged) {
      classroomMap['g'] = classroomGames;
      classroomMap['d'] = classroomDownloads;
      await database.rawUpdate(
        'UPDATE `Classroom` SET `content`=?,`contentVersion`=`contentVersion`+1 WHERE `id`=?',
        [convert.jsonEncode(classroomMap), classroomId],
      );
    }
  }

  await database.execute('DROP INDEX IF EXISTS `index_Game_classroomId_name`');
  await database.execute('DROP INDEX IF EXISTS `index_Game_bookId`');

  await database.execute('CREATE TABLE IF NOT EXISTS `Game_new` ('
      '`id` INTEGER,'
      ' `classroomId` INTEGER NOT NULL,'
      ' `k` TEXT NOT NULL,'
      ' `name` TEXT NOT NULL,'
      ' `hash` TEXT NOT NULL,'
      ' `data` TEXT NOT NULL,'
      ' `service` TEXT NOT NULL,'
      ' `createTime` INTEGER NOT NULL,'
      ' PRIMARY KEY (`id`))');
  await database.execute('INSERT INTO `Game_new`'
      ' (`id`,`classroomId`,`k`,`name`,`hash`,`data`,`service`,`createTime`)'
      ' SELECT `id`,`classroomId`,`k`,`name`,`hash`,`data`,`service`,`createTime`'
      ' FROM `Game`');
  await database.execute('DROP TABLE `Game`');
  await database.execute('ALTER TABLE `Game_new` RENAME TO `Game`');
  await database.execute('CREATE UNIQUE INDEX `index_Game_classroomId_name` ON `Game` (`classroomId`, `name`)');

  // 游戏和字体/提示的登记指纹作废，下次进课堂重新登记
  await database.rawDelete('DELETE FROM `CrKv` WHERE `k`=?', ['classroomResourceVersion']);
});
