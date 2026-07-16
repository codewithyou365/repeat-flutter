import 'package:floor/floor.dart';

final m5_6 = Migration(5, 6, (database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS `AssistiveTouchAction` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `sourceIndex` INTEGER NOT NULL, `instructionText` TEXT NOT NULL, `targetIndex` INTEGER NOT NULL, `enableAudio` INTEGER NOT NULL, `addToNextVerse` INTEGER NOT NULL, `sort` INTEGER NOT NULL)');
});
