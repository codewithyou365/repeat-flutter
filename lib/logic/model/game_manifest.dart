/// 游戏包的 manifest.json，以及课堂里记下来的订阅。
///
/// 一个游戏包（zip）里带一份 manifest.json，声明版本号、订阅服务器地址和**多个**游戏入口，
/// 一次订阅能装出好几个游戏（typing 那个包里就有 type / blank_it_right / word_slicer / japanese）。
/// 包内的 manifest 没有 [zip] 和 [hash]——zip 没法自含自己的 sha1，这两个字段由服务器注入。
library;

/// manifest 里的一个游戏入口。
class GameManifestEntry {
  /// 入口的稳定标识，升级时按它匹配老条目，**不能拿它当游戏名**。
  final String key;

  /// 建议的游戏名。装进课堂后用户能改名，升级时以用户改过的名字为准。
  final String name;

  /// 入口 js，相对解压目录，允许带子目录（如 'service/type.js'）。
  final String service;

  /// 运行期 key，装进课堂后写进条目的 'k'，原样喂给游戏
  /// （见 game_server/controller/game_key.dart，网页拿它决定进哪个游戏页面，如 'BlankItRight'）。
  /// manifest 里写 'contentKey'（也认简写 'k'）。为空表示包不指定，由用户自己填。
  final String contentKey;

  GameManifestEntry({
    required this.key,
    required this.name,
    required this.service,
    this.contentKey = '',
  });

  static GameManifestEntry? fromJsonOrNull(dynamic json) {
    if (json is! Map) return null;
    final key = (json['key'] ?? '').toString().trim();
    final service = (json['service'] ?? '').toString().trim();
    if (key.isEmpty || service.isEmpty) return null;
    var name = (json['name'] ?? '').toString().trim();
    if (name.isEmpty) name = key;
    var contentKey = (json['contentKey'] ?? '').toString().trim();
    if (contentKey.isEmpty) contentKey = (json['k'] ?? '').toString().trim();
    return GameManifestEntry(key: key, name: name, service: service, contentKey: contentKey);
  }
}

class GameManifest {
  /// 包名，只用来给订阅取个显示名。
  final String name;

  /// 单调递增的整数，升级判断只比大小，不做 semver 解析。
  final int version;

  /// 本包的「家」：本地导入的包也能靠它订阅到后续更新。可以为空。
  final String server;

  /// zip 的地址，相对 manifest 的 URL 解析。只有服务器返回的 manifest 才有。
  final String zip;

  /// zip 的 sha1，用来校验下载。只有服务器返回的 manifest 才有，为空就跳过校验。
  final String hash;

  final List<GameManifestEntry> games;

  GameManifest({
    required this.name,
    required this.version,
    required this.server,
    required this.zip,
    required this.hash,
    required this.games,
  });

  /// 解析失败或没有任何合法入口都返回 null——调用方一律当「这不是个订阅包」处理。
  static GameManifest? fromJsonOrNull(dynamic json) {
    if (json is! Map) return null;
    final rawGames = json['games'];
    if (rawGames is! List) return null;
    final games = <GameManifestEntry>[];
    for (final e in rawGames) {
      final entry = GameManifestEntry.fromJsonOrNull(e);
      if (entry != null) games.add(entry);
    }
    if (games.isEmpty) return null;

    // key 在包内必须唯一，重复的只留第一条，否则升级时匹配会串。
    final seen = <String>{};
    games.retainWhere((e) => seen.add(e.key));

    return GameManifest(
      name: (json['name'] ?? '').toString().trim(),
      version: _toInt(json['version']),
      server: (json['server'] ?? '').toString().trim(),
      zip: (json['zip'] ?? '').toString().trim(),
      hash: (json['hash'] ?? '').toString().trim(),
      games: games,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

/// 课堂内容 [Classroom.content] 的 'gs' 数组里的一条：装过的一个订阅。
///
/// 'g' 里的游戏条目用 'u' 回指到这里的 [url]。
class GameSubscription {
  /// manifest 的 URL，同时是这条订阅的主键。
  String url;

  /// 已装版本。
  int version;

  /// 已装 zip 的 sha1，跟 'g' 里那些条目的 'h' 一致。
  String hash;

  /// 包名，列表里显示用。
  String name;

  GameSubscription({
    required this.url,
    required this.version,
    required this.hash,
    required this.name,
  });

  static GameSubscription? fromJsonOrNull(dynamic json) {
    if (json is! Map) return null;
    final url = (json['u'] ?? '').toString();
    if (url.isEmpty) return null;
    return GameSubscription(
      url: url,
      version: GameManifest._toInt(json['v']),
      hash: (json['h'] ?? '').toString(),
      name: (json['n'] ?? '').toString(),
    );
  }

  static List<GameSubscription> toList(dynamic json) {
    if (json is! List) return [];
    final ret = <GameSubscription>[];
    for (final e in json) {
      final s = fromJsonOrNull(e);
      if (s != null) ret.add(s);
    }
    return ret;
  }

  Map<String, dynamic> toJson() {
    return {
      'u': url,
      'v': version,
      'h': hash,
      'n': name,
    };
  }
}
