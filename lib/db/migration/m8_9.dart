import 'package:floor/floor.dart';

final m8_9 = Migration(8, 9, (database) async {
  // 自定义动作原来所有课堂公用，现在改成按 classroomId 分开。
  // 目前该表还没有正式数据，直接重建。
  await database.execute('DROP TABLE IF EXISTS `AssistiveTouchAction`');
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `AssistiveTouchAction` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `name` TEXT NOT NULL, `sourceIndex` INTEGER NOT NULL, `templateIndex` INTEGER NOT NULL, `targetIndex` INTEGER NOT NULL, `enableAudio` INTEGER NOT NULL, `behavior` INTEGER NOT NULL, `sort` INTEGER NOT NULL)');
  await database.execute('CREATE INDEX `index_AssistiveTouchAction_classroomId` ON `AssistiveTouchAction` (`classroomId`)');
});
