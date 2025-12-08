import 'package:floor/floor.dart';

final m4_5 = Migration(4, 5, (database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS `GameUserScore` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `userId` INTEGER NOT NULL, `gameType` INTEGER NOT NULL, `score` INTEGER NOT NULL, `createDate` INTEGER NOT NULL)');
  await database.execute('CREATE TABLE IF NOT EXISTS `GameUserScoreHistory` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `userId` INTEGER NOT NULL, `gameType` INTEGER NOT NULL, `inc` INTEGER NOT NULL, `before` INTEGER NOT NULL, `after` INTEGER NOT NULL, `remark` TEXT NOT NULL, `createDate` INTEGER NOT NULL)');
  await database.execute('CREATE UNIQUE INDEX `index_GameUserScore_userId_gameType` ON `GameUserScore` (`userId`, `gameType`)');
  await database.execute('CREATE INDEX `index_GameUserScoreHistory_userId_gameType` ON `GameUserScoreHistory` (`userId`, `gameType`)');
  await database.execute('CREATE INDEX `index_GameUserScoreHistory_remark` ON `GameUserScoreHistory` (`remark`)');
});
