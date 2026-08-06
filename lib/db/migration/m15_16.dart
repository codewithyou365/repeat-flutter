import 'package:floor/floor.dart';

/// 课堂加内容字段：对标 Book.content，网络编辑可以按"课堂"这个单位整体编辑，
/// 课堂分享/导入也在这份 JSON 上再挂 'b' 数组塞所有书本。
///
/// Classroom 表里都是用户自己建的课堂，不能整表重建，只加列。老课堂补 '{}'。
final m15_16 = Migration(15, 16, (database) async {
  await database.execute("ALTER TABLE `Classroom` ADD COLUMN `content` TEXT NOT NULL DEFAULT '{}'");
  await database.execute('ALTER TABLE `Classroom` ADD COLUMN `contentVersion` INTEGER NOT NULL DEFAULT 0');
});
