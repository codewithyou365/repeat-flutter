import 'package:floor/floor.dart';

final m6_7 = Migration(6, 7, (database) async {
  // instructionText 换成 templateIndex（动态取模版渲染，而不是记录当时渲染好的固定文本），
  // 目前该表还没有正式数据，直接重建。
  await database.execute('DROP TABLE IF EXISTS `AssistiveTouchAction`');
  await database.execute('CREATE TABLE IF NOT EXISTS `AssistiveTouchAction` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `sourceIndex` INTEGER NOT NULL, `templateIndex` INTEGER NOT NULL, `targetIndex` INTEGER NOT NULL, `enableAudio` INTEGER NOT NULL, `addToNextVerse` INTEGER NOT NULL, `sort` INTEGER NOT NULL)');
});
