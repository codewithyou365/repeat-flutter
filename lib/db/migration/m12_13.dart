import 'package:floor/floor.dart';

/// 自定义动作加"参数数量"：指令模版里可以写 {{input1}}..{{input10}}，
/// 执行前弹框让用户依次填。老动作没有参数，补 0。
///
/// 这张表现在可能已经有用户自己配的动作了，不能再像 m6_7/m8_9 那样整表重建，
/// 只加列。
final m12_13 = Migration(12, 13, (database) async {
  await database.execute('ALTER TABLE `AssistiveTouchAction` ADD COLUMN `inputCount` INTEGER NOT NULL DEFAULT 0');
});
