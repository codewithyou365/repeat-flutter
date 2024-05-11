import 'package:floor/floor.dart';

final m1_2 = Migration(1, 2, (database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS `Classroom` (`name` TEXT NOT NULL, `arg` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`name`))');
  await database.execute('CREATE UNIQUE INDEX `index_Classroom_sort` ON `Classroom` (`sort`)');
});
