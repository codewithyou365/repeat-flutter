import 'package:floor/floor.dart';

final m2_3 = Migration(2, 3, (database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS `VideoAttribute` (`path` TEXT NOT NULL, `maskRatio` REAL NOT NULL, PRIMARY KEY (`path`))');
});
