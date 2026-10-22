/// 课堂里的一个游戏，来自 [Classroom.content] 的 'g' 数组里的一条。
///
/// [index] 是它在 'g' 数组里的下标，所有写操作都按这个下标定位原始 map，
/// 这样能就地改字段、保住 'i' 和别的未知 key。
class GameItem {
  final int index;

  /// 'i'：App 回写的 Game.id。改名要保住它，否则 registerRes 会走"删旧建新"，
  /// 游戏存档和分数就没了。
  final int? id;

  /// 'h'：指向课堂 'd' 里那个 zip 的 sha1。
  final String hash;

  /// 'n' 游戏名，课堂内唯一。
  final String name;

  /// 'k' 游戏 key。
  final String key;

  /// 's' 入口 js 文件。
  final String service;

  /// zip 在课堂 'd' 里的原始文件名，'d' 里找不到就是 null。
  final String? zipName;

  /// zip 文件本身在不在磁盘上。
  final bool zipExists;

  /// zip 解压出来的目录在不在。游戏能不能跑看这个。
  final bool unpacked;

  /// 'u'：来自哪个订阅（manifest URL）。空 = 本地导入的。
  final String subUrl;

  /// 'ek'：manifest 里那个入口的 key。跟 [subUrl] 一起做升级匹配。
  final String entryKey;

  /// 订阅的显示名，来自 'gs' 里那条的 'n'。本地导入的是空的。
  final String subName;

  /// 订阅当前已装的版本，来自 'gs' 里那条的 'v'。本地导入的是 0。
  final int subVersion;

  bool get fromSubscription => subUrl.isNotEmpty;

  GameItem({
    required this.index,
    required this.id,
    required this.hash,
    required this.name,
    required this.key,
    required this.service,
    required this.zipName,
    required this.zipExists,
    required this.unpacked,
    this.subUrl = '',
    this.entryKey = '',
    this.subName = '',
    this.subVersion = 0,
  });
}

/// 订阅装出来的一个提示服务，来自 [Classroom.content] 的 'ts' 数组里的一条。
///
/// 只是个目录：提示字段挑服务时从这里选，选中后把 'h'/'s' 抄到字段块上。
class TipServiceItem {
  /// 'h'：指向课堂 'd' 里那个 zip 的 sha1。
  final String hash;

  /// 'n'：manifest 里的名字。
  final String name;

  /// 's'：入口 js。
  final String service;

  /// zip 解压出来的目录在不在。
  final bool unpacked;

  /// 'u'：来自哪个订阅（manifest URL）。
  final String subUrl;

  /// 'ek'：manifest 里那个入口的 key。
  final String entryKey;

  final String subName;

  final int subVersion;

  TipServiceItem({
    required this.hash,
    required this.name,
    required this.service,
    required this.unpacked,
    required this.subUrl,
    required this.entryKey,
    required this.subName,
    required this.subVersion,
  });
}
