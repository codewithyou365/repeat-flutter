import 'package:floor/floor.dart';

final m3_4 = Migration(3, 4, (database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS `EditBookHistory` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `bookId` INTEGER NOT NULL, `commitDate` INTEGER NOT NULL, `content` TEXT NOT NULL)');
  await database.execute('CREATE UNIQUE INDEX `index_EditBookHistory_commitDate_bookId` ON `EditBookHistory` (`commitDate`, `bookId`)');
});
