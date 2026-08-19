import 'package:floor/floor.dart';

/// 新增 GameKv：游戏脚本自己的键值表（打字游戏的熟词库就住在这儿）。
///
/// 建表语句跟 database.g.dart 里 floor 生成的那句保持逐字一致，
/// 否则老库升上来的表结构会跟新装的不一样。
final m21_22 = Migration(21, 22, (database) async {
  await database.execute(
    'CREATE TABLE IF NOT EXISTS `GameKv` (`gameId` INTEGER NOT NULL, `k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`gameId`, `k`))',
  );
});
