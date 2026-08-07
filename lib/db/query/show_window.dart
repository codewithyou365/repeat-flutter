/// 列表页的「骨架 id 列表 + 有界正文窗口」。
///
/// 列表骨架只拿一串 id（一条 8 字节，十万条也就几百 KB），够撑起 itemCount、
/// 滚动定位和总数；正文只保当前可视区附近的一段，滚出去就淘汰。这样不管课堂
/// 多大，列表页占的内存都是常数 —— 以前是把整个课堂的正文常驻内存做内存过滤。
class ShowWindow<T> {
  /// 一次补多少行。比一屏多几行，来回小幅滚动不会反复打 SQL。
  static const int pageSize = 60;

  /// 窗口里最多留多少行正文。留 4 页的余量，来回滚不会把刚看过的挤掉。
  static const int capacity = 240;

  final Future<List<T>> Function(List<int> ids) fetch;
  final int Function(T row) idOf;

  /// 补齐一页后回调，让界面重画。
  final void Function() onLoaded;

  List<int> ids = [];

  /// Dart 的 Map 保插入序，直接拿来当淘汰序用。
  final Map<int, T> _byId = {};
  final Set<int> _loading = {};

  /// 查不到的 id（行被删了）。不记下来的话每次 build 都会再发一次查询。
  final Set<int> _missing = {};

  ShowWindow({
    required this.fetch,
    required this.idOf,
    required this.onLoaded,
  });

  int get length => ids.length;

  bool get isEmpty => ids.isEmpty;

  /// 换了过滤条件/排序：重置骨架，正文全丢。
  void reset(List<int> newIds) {
    ids = newIds;
    _byId.clear();
    _loading.clear();
    _missing.clear();
  }

  /// 内容被改过：正文重取，骨架不动（id 和顺序没变）。
  void invalidate() {
    _byId.clear();
    _loading.clear();
    _missing.clear();
  }

  int indexOfId(int id) => ids.indexOf(id);

  T? byId(int id) => _byId[id];

  /// 取第 [index] 行。不在窗口里就返回 null 并异步补齐，补完回调 [onLoaded]。
  /// 调用方遇到 null 渲染一个占位就行。
  T? at(int index) {
    if (index < 0 || index >= ids.length) {
      return null;
    }
    var row = _byId[ids[index]];
    if (row == null) {
      _load(index);
    }
    return row;
  }

  void _load(int index) {
    var start = index - pageSize ~/ 2;
    if (start < 0) {
      start = 0;
    }
    var end = start + pageSize;
    if (end > ids.length) {
      end = ids.length;
    }
    var want = <int>[];
    for (var i = start; i < end; i++) {
      var id = ids[i];
      if (!_byId.containsKey(id) && !_loading.contains(id) && !_missing.contains(id)) {
        want.add(id);
      }
    }
    if (want.isEmpty) {
      return;
    }
    _loading.addAll(want);
    fetch(want).then((rows) {
      for (var row in rows) {
        _byId[idOf(row)] = row;
      }
      for (var id in want) {
        _loading.remove(id);
        if (!_byId.containsKey(id)) {
          _missing.add(id);
        }
      }
      _evict();
      onLoaded();
    }).catchError((Object _) {
      _loading.removeAll(want);
    });
  }

  void _evict() {
    while (_byId.length > capacity) {
      _byId.remove(_byId.keys.first);
    }
  }
}
