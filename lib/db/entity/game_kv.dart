// entity/game_kv.dart

import 'package:floor/floor.dart';

/// 游戏自己的键值表：给 JS 游戏服务（[Game.service]）当一张通用的小表用。
///
/// 跟 [Game.data] 那个 JSON blob 的分工：
/// - [Game.data] 存"整份配置/进度"，每次读写都是整块 JSON，条目多了越写越重，
///   而且它会跟着课堂分享文档一起导出（见 ClassroomDocHelp.fillGameData）。
/// - GameKv 存"条目会一直长下去、要按 key 单条读写"的数据（比如打字游戏的熟词库），
///   不进分享文档，纯粹是本机这台设备的学习数据。
///
/// [k] 故意用裸字符串而不是枚举：key 的含义由各个游戏脚本自己定义（约定用
/// `<前缀>:<名字>` 分命名空间，比如熟词是 `fw:apple`），Dart 这边不认识也不需要认识。
@Entity(primaryKeys: ['gameId', 'k'])
class GameKv {
  final int gameId;
  final String k;
  final String value;

  GameKv(
    this.gameId,
    this.k,
    this.value,
  );
}
