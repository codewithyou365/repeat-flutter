import 'dart:convert' as convert;

import 'package:floor/floor.dart';

/// 书名从 Book.name 这一列搬进 Book.content 的 'n'。
///
/// 这样网络编辑的课堂文档里改书名就是改内容本身，不用再单独维护一套书本元数据。
/// SQL 那边取书名一律改成 `json_extract(Book.content,'$.n')`。
///
/// 搬名字这一步在 Dart 里做，不用 json_set()：老设备的 SQLite 不一定带 JSON1，
/// 而且有些书的 content 是空串（BookDao.add 建出来的空书），json_set 遇到它会返回 NULL 把内容清掉。
///
/// SQLite 到 3.35 才有 DROP COLUMN，minSdk 24 的机器上没有，所以整表重建。
final m16_17 = Migration(16, 17, (database) async {
  final books = await database.rawQuery('SELECT `id`,`name`,`content` FROM `Book`');
  for (final book in books) {
    final name = (book['name'] as String?) ?? '';
    final content = (book['content'] as String?) ?? '';
    Map<String, dynamic> map;
    try {
      final decoded = convert.jsonDecode(content);
      map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (e) {
      map = <String, dynamic>{};
    }
    map['n'] = name;
    await database.rawUpdate(
      'UPDATE `Book` SET `content`=? WHERE `id`=?',
      [convert.jsonEncode(map), book['id']],
    );
  }

  await database.execute('DROP INDEX IF EXISTS `index_Book_classroomId_name`');
  await database.execute('DROP INDEX IF EXISTS `index_Book_classroomId_sort`');
  await database.execute('DROP INDEX IF EXISTS `index_Book_classroomId_updateTime`');
  await database.execute('DROP INDEX IF EXISTS `index_Book_sort_id`');

  await database.execute('CREATE TABLE IF NOT EXISTS `Book_new` ('
      '`id` INTEGER PRIMARY KEY AUTOINCREMENT,'
      ' `classroomId` INTEGER NOT NULL,'
      ' `desc` TEXT NOT NULL,'
      ' `enable` INTEGER NOT NULL,'
      ' `url` TEXT NOT NULL,'
      ' `content` TEXT NOT NULL,'
      ' `contentVersion` INTEGER NOT NULL,'
      ' `sort` INTEGER NOT NULL,'
      ' `createTime` INTEGER NOT NULL,'
      ' `updateTime` INTEGER NOT NULL)');
  await database.execute('INSERT INTO `Book_new`'
      ' (`id`,`classroomId`,`desc`,`enable`,`url`,`content`,`contentVersion`,`sort`,`createTime`,`updateTime`)'
      ' SELECT `id`,`classroomId`,`desc`,`enable`,`url`,`content`,`contentVersion`,`sort`,`createTime`,`updateTime`'
      ' FROM `Book`');
  await database.execute('DROP TABLE `Book`');
  await database.execute('ALTER TABLE `Book_new` RENAME TO `Book`');

  // 书名的唯一性没有了索引兜底，改由 BookDao.add/addTo 在 Dart 里查重
  await database.execute('CREATE UNIQUE INDEX `index_Book_classroomId_sort` ON `Book` (`classroomId`, `sort`)');
  await database.execute('CREATE INDEX `index_Book_classroomId_updateTime` ON `Book` (`classroomId`, `updateTime`)');
  await database.execute('CREATE INDEX `index_Book_sort_id` ON `Book` (`sort`, `id`)');
});
