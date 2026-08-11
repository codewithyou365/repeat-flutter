import 'package:floor/floor.dart';

/// 悬浮球的动作全部改成存在 Classroom.content 的 'at' 数组里：
/// 以前的"内置动作"（存在 CrKv 的 assistiveTouchVisibleBuiltins 里的一串枚举名）和
/// "自定义动作"（AssistiveTouchAction 表）合并成同一种东西，参数按类型走。
///
/// 老配置不迁移：内置动作是枚举名 + 一份共用的后退秒数，自定义动作只有联网那一种，
/// 两边的参数结构跟新的对不上，硬搬过去只会搬出一堆半残的动作。
/// 用户下次进课堂会拿到默认的两个动作（播放/暂停、后退 3 秒），再自己加想要的。
///
/// CrK 里那两个枚举值要留着不能删：CrKvConverter 是用 CrK.values.byName 反解的，
/// 老库里只要还剩一行就会在查询时抛异常，所以这里把行删掉，枚举值原样保留。
final m19_20 = Migration(19, 20, (database) async {
  await database.rawDelete(
    'DELETE FROM `CrKv` WHERE `k` IN (?,?)',
    ['assistiveTouchVisibleBuiltins', 'assistiveTouchSeekBackSeconds'],
  );
  await database.execute('DROP TABLE IF EXISTS `AssistiveTouchAction`');
});
