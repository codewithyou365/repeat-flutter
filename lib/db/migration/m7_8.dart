import 'package:floor/floor.dart';

final m7_8 = Migration(7, 8, (database) async {
  // addToNextVerse 换成 behavior（0：请求并覆盖到作用位置；1：作用位置有内容则播放，否则覆盖），
  // 目前该表还没有正式数据，直接重建。
  await database.execute('DROP TABLE IF EXISTS `AssistiveTouchAction`');
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `AssistiveTouchAction` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `sourceIndex` INTEGER NOT NULL, `templateIndex` INTEGER NOT NULL, `targetIndex` INTEGER NOT NULL, `enableAudio` INTEGER NOT NULL, `behavior` INTEGER NOT NULL, `sort` INTEGER NOT NULL)');
});
