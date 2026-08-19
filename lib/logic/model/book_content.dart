class BookContent {
  String? showType;
  String? rootUrl;
  List<DownloadContent>? download;

  /// 整节媒体的 hash（'m'），跟 [showType] 是一对：'s' 说整节媒体怎么显示，'m' 说是哪个文件。
  /// 见 [VerseField.findSectionDownload]。
  String? mediaHash;
  List<ChapterContent> chapter;

  BookContent({
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.chapter,
    this.mediaHash,
  });

  factory BookContent.fromJson(Map<String, dynamic> json) {
    return BookContent(
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      mediaHash: json[VerseField.sectionMediaHash] as String?,
      chapter: (json['c'] as List?)?.map((e) => ChapterContent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      if (mediaHash != null) VerseField.sectionMediaHash: mediaHash,
      'c': chapter.map((e) => e.toJson()).toList(),
    };
  }
}

class DownloadContent {
  String url;
  String hash;

  // Custom display name given by the user. When null, [name] (hash-based) is used.
  String? n;

  String get extension => url.split('.').last;

  String get folder => hash.substring(0, 2);

  String get pureName => hash.substring(2);

  String get name => "$pureName.$extension";

  String get path => "$folder/$name";

  DownloadContent({
    required this.url,
    required this.hash,
    this.n,
  });

  static List<DownloadContent>? toList(dynamic json) {
    if (json != null) {
      return (json as List).map((e) => DownloadContent.fromJson(e as Map<String, dynamic>)).toList();
    }
    return null;
  }

  static DownloadContent? fromJsonOrNull(dynamic json) {
    if (json is Map<String, dynamic>) {
      return DownloadContent.fromJson(json);
    }
    return null;
  }

  factory DownloadContent.fromJson(Map<String, dynamic> json) {
    return DownloadContent(
      url: json['u'] as String,
      hash: json['h'] as String,
      n: json['n'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final ret = <String, dynamic>{
      'u': url,
      'h': hash,
    };
    if (n != null) {
      ret['n'] = n;
    }
    return ret;
  }
}

class ChapterContent {
  int? id;
  String? showType;
  String? rootUrl;
  List<DownloadContent>? download;

  /// 整节媒体的 hash（'m'）。整章共用一个音视频时只在这里写一次，每一节都继承得到。
  /// 见 [VerseField.findSectionDownload]。
  String? mediaHash;
  List<VerseContent> verse;

  ChapterContent({
    required this.id,
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.verse,
    this.mediaHash,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      id: json['i'] as int?,
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      mediaHash: json[VerseField.sectionMediaHash] as String?,
      verse: (json['v'] as List?)?.map((e) => VerseContent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'i': id,
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      if (mediaHash != null) VerseField.sectionMediaHash: mediaHash,
      'v': verse.map((e) => e.toJson()).toList(),
    };
  }
}

/// q/a/t 三个字段各自的那一小块：
/// `'a': {'text': 答案正文, 'mediaHash': ..., 'start': ..., 'end': ..., 'showType': ...}`。
///
/// - 'text'：这个字段的正文。只看本层，不继承。
/// - 'mediaHash'：字段专属媒体的 hash。文件对象本身只存在 book/chapter/verse 的 'd' 列表里
///   （跟字体的 'fontHash' 一个套路），这里只是引用；'start'/'end' 是相对这个文件的时间。
///   没有 mediaHash 时沿用整节媒体（顶层的 'm'，见 [VerseField.findSectionDownload]）。
/// - 'showType'：字段专属视图类型。整节的 's' 是 q/a 共用的，一节里 q 是视频、a 是音频时
///   必须各记各的，不能靠改 's' 来表达。
/// - 'start'/'end'：区间，逐节各不相同，只看本层。
///
/// 字段块跟 's' 一样是逐层继承的：'mediaHash'/'showType' 先看 verse，没有就用 chapter、
/// 再没有用 book（见 [lookup]）——整章共用一个媒体时只要在 chapter 上写一次，
/// 不用每一节都抄一遍。'text' 和 'start'/'end' 是每节自己的，不继承。
///
/// 笔记（'n'）没有媒体和区间，正文仍然直接平铺成 `'n': '...'`，所以取正文一律走
/// [getText]/[setText]，别自己去索引 map。
///
/// 提示（'t'）是一个数组，一节可以挂好几条（词源、语法、背景……）：
/// `'t': [{'text': ..}, {'text': ..}]`。定位某一条用「字段引用串」而不是裸 acronym：
/// 't' 是第 1 条、't1' 是第 2 条、't2' 是第 3 条（见 [ref]/[baseOf]/[indexOf]），
/// 这样所有只传 'q'/'a'/'t'/'n' 的老调用点都还落在原来那一条上。
/// 提示的名字（tab 上显示的）、字体和提示服务配置统一定义在 **课堂**（Classroom.content）
/// 的 't' 数组里（见 [tipNameOf] 和 ClassroomDocField），book 那一层不再有 't'，
/// verse 的 't' 只放正文/媒体/区间——整个课堂第 i 个 tab 名字一致，翻书翻页时 tab 才不会跳。
///
/// book 那一层的字段块里放着 'q'/'a'/'n' 的字体（'fontSize'/'fontAlias'/'fontHash'）和
/// 提示服务配置（'h'/'k'/'s'/'i'，写进 Tip 表，见 ClassroomHelp.registerRes）；
/// 提示那几条的同名 key 在课堂那一层，块结构完全一样，读写照样走 [of]/[getStr]/[setStr]。
/// 几拨 key 互不重名，各读各的。
class VerseField {
  static const String text = 'text';
  static const String mediaHash = 'mediaHash';
  static const String start = 'start';
  static const String end = 'end';
  static const String showType = 'showType';
  static const String fontSize = 'fontSize';
  static const String fontAlias = 'fontAlias';
  static const String fontHash = 'fontHash';

  /// 整节媒体的 hash。这个键不在字段块里，而是跟 's'（整节视图类型）并排放在
  /// book/chapter/verse 的顶层：'s' 说整节媒体怎么显示，'m' 说整节媒体是哪个文件。
  /// 见 [findSectionDownload]。
  static const String sectionMediaHash = 'm';

  /// 课堂 't' 数组里那一条的名字，显示在提示 tab 上。
  static const String tipName = 'n';

  /// 提示 tab 最多渲染几条：tab 行不滚动，再多就挤不下了。
  /// 只是渲染上限，不动数据，超出的条目原样留在 JSON 里。
  static const int maxTip = 8;

  /// verse 一层有嵌套字段块的字段（QaType 里只有 'n' 例外，它的正文是平铺的）。
  static const List<String> acronyms = ['q', 'a', 't'];

  /// 会存成数组的字段：一个字段有好几条时用下标区分。
  static const List<String> listAcronyms = ['t'];

  static bool nested(String acronym) => acronyms.contains(baseOf(acronym));

  /// 第 [index] 条的字段引用串。第 1 条就是裸 acronym，这样老数据/老调用点不用动。
  static String ref(String acronym, int index) => index == 0 ? acronym : '$acronym$index';

  /// 't2' -> 't'；'q' -> 'q'。
  static String baseOf(String ref) {
    final i = _digitAt(ref);
    return i < 0 ? ref : ref.substring(0, i);
  }

  /// 't2' -> 2；'q' -> 0。
  static int indexOf(String ref) {
    final i = _digitAt(ref);
    return i < 0 ? 0 : (int.tryParse(ref.substring(i)) ?? 0);
  }

  /// 引用串里数字下标的起点，没有下标返回 -1。
  static int _digitAt(String ref) {
    for (var i = 0; i < ref.length; i++) {
      final c = ref.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39) {
        return i == 0 ? -1 : i;
      }
    }
    return -1;
  }

  /// 这一节该显示几个提示 tab：verse 和课堂里 't' 数组谁长按谁算（课堂定义了名字，
  /// verse 可能只写了前几条的正文），至少 1 个，最多 [maxTip] 个。
  static int tipCount(Map<String, dynamic>? verse, Map<String, dynamic>? classroom) {
    var count = 1;
    for (var content in [verse, classroom]) {
      if (content == null) {
        continue;
      }
      final v = content['t'];
      if (v is List && v.length > count) {
        count = v.length;
      }
    }
    return count > maxTip ? maxTip : count;
  }

  /// 第 [index] 条提示的名字，没写就返回 null（调用方自己决定显示什么）。
  /// [classroom] 是 Classroom.content 解出来的 map——名字定义在课堂那一层。
  static String? tipNameOf(Map<String, dynamic>? classroom, int index) {
    if (classroom == null) {
      return null;
    }
    return getStr(classroom, ref('t', index), tipName);
  }

  /// 字段块本身，没有就返回 null（不会顺手建出来）。
  ///
  /// 数组字段（'t'）按引用串里的下标取；还没迁移成数组的老内容是个 map，
  /// 那就只有第 1 条。
  static Map<String, dynamic>? of(Map<String, dynamic> content, String fieldRef) {
    final v = content[baseOf(fieldRef)];
    final index = indexOf(fieldRef);
    if (v is List) {
      if (index >= v.length) {
        return null;
      }
      final ret = v[index];
      return ret is Map<String, dynamic> ? ret : null;
    }
    if (v is Map<String, dynamic>) {
      return index == 0 ? v : null;
    }
    return null;
  }

  static Map<String, dynamic> _ensure(Map<String, dynamic> content, String fieldRef) {
    final base = baseOf(fieldRef);
    final index = indexOf(fieldRef);
    if (!listAcronyms.contains(base)) {
      var ret = of(content, fieldRef);
      if (ret == null) {
        ret = <String, dynamic>{};
        content[base] = ret;
      }
      return ret;
    }
    final raw = content[base];
    // 老内容是 map 的话就地包成数组，省得再等一次迁移。
    final list = raw is List
        ? raw
        : <dynamic>[
            if (raw is Map<String, dynamic>) raw,
          ];
    // 中间缺的条目补空块：下标就是身份，不能靠挪位置来省这几个 {}。
    while (list.length <= index) {
      list.add(<String, dynamic>{});
    }
    var ret = list[index];
    if (ret is! Map<String, dynamic>) {
      ret = <String, dynamic>{};
      list[index] = ret;
    }
    content[base] = list;
    return ret;
  }

  static String? getStr(Map<String, dynamic> content, String fieldRef, String key) {
    final v = of(content, fieldRef)?[key];
    if (v is String && v.isNotEmpty) {
      return v;
    }
    return null;
  }

  /// 传 null 或空串就把这个 key 删掉；删完字段块空了连块一起删，避免留下一堆 `'t': {}`。
  static void setStr(Map<String, dynamic> content, String fieldRef, String key, String? value) {
    if (value == null || value.isEmpty) {
      remove(content, fieldRef, [key]);
      return;
    }
    _ensure(content, fieldRef)[key] = value;
  }

  static void remove(Map<String, dynamic> content, String fieldRef, List<String> keys) {
    final field = of(content, fieldRef);
    if (field == null) {
      return;
    }
    for (var key in keys) {
      field.remove(key);
    }
    if (field.isNotEmpty) {
      return;
    }
    final base = baseOf(fieldRef);
    final raw = content[base];
    if (raw is! List) {
      content.remove(base);
      return;
    }
    // 数组字段清空一条时只留个空块：从中间删掉会让后面每一条的下标（也就是它的名字、
    // 字体、提示服务）整体前移。只有末尾连着空的才能截掉。
    while (raw.isNotEmpty && _emptyField(raw.last)) {
      raw.removeLast();
    }
    if (raw.isEmpty) {
      content.remove(base);
    }
  }

  static bool _emptyField(dynamic field) {
    if (field == null) {
      return true;
    }
    return field is Map && field.isEmpty;
  }

  static String? _rawText(Map<String, dynamic> content, String fieldRef) {
    if (!nested(fieldRef)) {
      final v = content[fieldRef];
      return v is String && v.isNotEmpty ? v : null;
    }
    return getStr(content, fieldRef, text);
  }

  /// 分隔符字符：扩展助手覆盖写入时会在正文末尾挂一段「指令」，见 [embedInstruction]。
  static const String _mark = '•';

  /// [s] 里最长连续 [_mark] 的游程长度。
  static int _maxMarkRun(String s) {
    var max = 0, run = 0;
    for (final r in s.runes) {
      if (r == _mark.runes.first) {
        run++;
        if (run > max) max = run;
      } else {
        run = 0;
      }
    }
    return max;
  }

  /// 分隔符取正文/指令里最长连续 [_mark] 游程再加一个，保证分隔符这一整行
  /// 不会跟正文/指令里天然出现的 [_mark] 混淆。
  static String _delimiter(String content, String instruction) {
    final n = (_maxMarkRun(content) > _maxMarkRun(instruction) ? _maxMarkRun(content) : _maxMarkRun(instruction)) + 1;
    return _mark * n;
  }

  /// 把 [instruction] 挂到 [content] 末尾：`正文\n\n\n\n分隔符\n指令\n分隔符`。
  /// 正文和分隔符之间空几行，纯粹是为了显示时不挤在一起，不影响拆分（[_splitInstruction]
  /// 只认最后两条分隔符之间的部分是指令，中间空多少行都无所谓）。
  /// 扩展助手 playOrOverwrite 靠这个存的指令跟下次要发的指令比对，见 [getInstruction]。
  static String embedInstruction(String content, String instruction) {
    final delim = _delimiter(content, instruction);
    return '$content\n\n\n\n$delim\n$instruction\n$delim';
  }

  /// 从 [raw] 里拆出正文和指令：最后一行如果整行都是 [_mark]（长度记为 n），
  /// 就往上找第一处同样是 n 个 [_mark] 的整行，两条分隔符之间是指令，之前是正文；
  /// 找不到匹配（老数据/手填内容，没挂过指令块）就整段当正文，指令为 null。
  static ({String content, String? instruction}) _splitInstruction(String raw) {
    final lines = raw.split('\n');
    if (lines.length < 3) {
      return (content: raw, instruction: null);
    }
    final closeLine = lines.last;
    if (closeLine.isEmpty || !closeLine.runes.every((r) => r == _mark.runes.first)) {
      return (content: raw, instruction: null);
    }
    for (var i = lines.length - 2; i >= 1; i--) {
      if (lines[i] == closeLine) {
        return (
          content: lines.sublist(0, i).join('\n'),
          instruction: lines.sublist(i + 1, lines.length - 1).join('\n'),
        );
      }
    }
    return (content: raw, instruction: null);
  }

  /// 正文。'n'（笔记）没有字段块，直接平铺存。
  /// 扩展助手写入时可能在正文末尾挂了一段指令（见 [embedInstruction]），原样返回——
  /// 指令要能在正文里看得见（编辑页/导出都读这个），只有比对要不要重新生成时才需要拆开，
  /// 见 [getInstruction]。
  static String? getText(Map<String, dynamic> content, String fieldRef) {
    return _rawText(content, fieldRef);
  }

  /// 取出正文末尾挂着的指令（扩展助手 playOrOverwrite 用来判断要不要重新生成），
  /// 没有挂过指令块（老数据/手填内容）返回 null。
  static String? getInstruction(Map<String, dynamic> content, String fieldRef) {
    final raw = _rawText(content, fieldRef);
    if (raw == null) {
      return null;
    }
    return _splitInstruction(raw).instruction;
  }

  static void setText(Map<String, dynamic> content, String fieldRef, String? value) {
    if (!nested(fieldRef)) {
      if (value == null || value.isEmpty) {
        content.remove(fieldRef);
      } else {
        content[fieldRef] = value;
      }
      return;
    }
    setStr(content, fieldRef, text, value);
  }

  /// 逐层找一个字段属性：verse -> chapter -> book，第一个有值的算数。
  /// contents 按由近到远传（null 的层跳过）。数组字段按同一个下标逐层对齐。
  static String? lookup(List<Map<String, dynamic>?> contents, String fieldRef, String key) {
    for (var content in contents) {
      if (content == null) {
        continue;
      }
      final v = getStr(content, fieldRef, key);
      if (v != null) {
        return v;
      }
    }
    return null;
  }

  /// 按 hash 在这几层的 'd' 列表里找文件对象。字段媒体、字体都只存 hash，文件对象统一在 'd' 里。
  static DownloadContent? findDownloadByHash(List<Map<String, dynamic>?> contents, String hash) {
    for (var content in contents) {
      if (content == null) {
        continue;
      }
      final list = DownloadContent.toList(content['d']);
      if (list == null) {
        continue;
      }
      for (var d in list) {
        if (d.hash == hash) {
          return d;
        }
      }
    }
    return null;
  }

  /// 整节媒体的文件对象：q/a/t 谁都没配字段专属媒体时，播的就是这一份。
  ///
  /// 'm' 按 verse -> chapter -> book 就近取（跟 's' 一样，整章共用一个媒体只在 chapter 上写一次），
  /// 拿到 hash 之后用 [findDownloadByHash] 跨所有层找文件对象——所以一节自己有了 'd'
  /// （比如扩展助手给某个字段生成的音频）也遮蔽不掉章节的整节媒体。
  ///
  /// 没有 'm' 的老数据/外部 doc JSON 回落到旧规则：就近那一层 'd' 的第一项。
  /// 迁移会给库里的数据补上 'm'，回落只为外部导入的内容兜底。
  static DownloadContent? findSectionDownload(List<Map<String, dynamic>?> contents) {
    for (var content in contents) {
      final hash = content?[sectionMediaHash];
      if (hash is String && hash.isNotEmpty) {
        final d = findDownloadByHash(contents, hash);
        if (d != null) {
          return d;
        }
        // 'm' 指着一个已经不在任何 'd' 里的文件（比如媒体被删了），当作没配，往下回落。
        break;
      }
    }
    for (var content in contents) {
      if (content == null) {
        continue;
      }
      final list = DownloadContent.toList(content['d']);
      if (list == null) {
        continue;
      }
      return list.isEmpty ? null : list.first;
    }
    return null;
  }

  /// 给还没有 'm' 的一层补上 'm' = 'd' 的第一项（旧规则里整节媒体就是它），补了返回 true。
  /// 内容从外面进来（导入外部 doc、迁移老库）时统一走这里，之后全 App 只认 'm'，
  /// 不用再各处判断"这层有没有 'd'、要不要就近覆盖"。
  static bool ensureSectionMediaHash(Map<String, dynamic> content) {
    if (content[sectionMediaHash] is String) {
      return false;
    }
    final list = DownloadContent.toList(content['d']);
    if (list == null || list.isEmpty) {
      return false;
    }
    content[sectionMediaHash] = list.first.hash;
    return true;
  }

  /// 换掉这一层的整节媒体：文件对象放到 'd' 的第一项，同时把 'm' 指过去。
  /// 两个必须一起改——只改 'd' 会让 'm' 还指着老文件，只改 'm' 会让文件对象没处登记。
  ///
  /// 'd' 里原有的其它文件对象要留着：那些是字段专属媒体（见 [setMedia]），
  /// 整个换掉会让字段块里的 mediaHash 变成找不到文件的悬空引用。
  static void setSectionMedia(Map<String, dynamic> content, DownloadContent d) {
    final list = DownloadContent.toList(content['d']) ?? [];
    list.removeWhere((e) => e.hash == d.hash);
    list.insert(0, d);
    content['d'] = list.map((e) => e.toJson()).toList();
    content[sectionMediaHash] = d.hash;
  }

  /// 给某个字段挂一份专属媒体：文件对象登记进这一节自己的 'd'，字段块里只写 mediaHash。
  ///
  /// 一律登记到 verse：文件是这一节的，放在这一节最好管理（删掉这节就跟着走）。
  /// 以前要退到 book 上，是因为整节媒体按"就近那一层 'd' 的第一项"算，
  /// 给原本没有 'd' 的 verse 凭空造一个 'd' 会把整节媒体顶掉；现在整节媒体由 'm' 显式指定、
  /// 文件对象用 [findDownloadByHash] 跨层解析（见 [findSectionDownload]），没有这个问题了。
  static void setMedia({
    required Map<String, dynamic> verse,
    required String acronym,
    required DownloadContent d,
  }) {
    addDownload(verse, d);
    setStr(verse, acronym, mediaHash, d.hash);
  }

  /// 保证 't' 数组至少有 [count] 条，不足的补空块。返回是否真的改了。
  /// 新增一条提示、或者清掉某条的名字后要把被 [remove] 截掉的占位补回来，都走这里。
  /// 下标就是提示的身份（名字/字体/提示服务在课堂上，正文在每一节上，全靠下标对齐），
  /// 所以永远只在末尾补，绝不从中间挪。
  static bool ensureTipCount(Map<String, dynamic> content, int count) {
    if (count <= 0 || tipLength(content) >= count) {
      return false;
    }
    _ensure(content, ref('t', count - 1));
    return true;
  }

  /// 这一节里实际写了内容的提示条数（跟 [tipCount] 不一样：那个是该显示几个 tab）。
  static int tipLength(Map<String, dynamic> content) {
    final v = content['t'];
    if (v is List) {
      return v.length;
    }
    return v == null ? 0 : 1;
  }

  /// 把文件对象登记进这一层的 'd' 列表（按 hash 去重）。
  /// 一定是追加：没有 'm' 的老内容按 'd' 的第一项算整节媒体（见 [findSectionDownload] 的回落），
  /// 插到前面会把整节的音视频换掉。换整节媒体请走 [setSectionMedia]。
  /// 返回是否真的改了。
  static bool addDownload(Map<String, dynamic> content, DownloadContent d) {
    final list = DownloadContent.toList(content['d']) ?? [];
    if (list.any((e) => e.hash == d.hash)) {
      return false;
    }
    list.add(d);
    content['d'] = list.map((e) => e.toJson()).toList();
    return true;
  }
}

/// 一条提示：'t' 数组里的一项。名字在 book 那一层定义，这里只有正文和媒体。
class VerseTipContent {
  String? text;
  String? mediaHash;
  String? showType;
  String? start;
  String? end;

  VerseTipContent({
    this.text,
    this.mediaHash,
    this.showType,
    this.start,
    this.end,
  });

  bool get isEmpty => text == null && mediaHash == null && showType == null && start == null && end == null;
}

class VerseContent {
  int? id;
  String? showType;
  String? rootUrl;
  List<DownloadContent>? download;
  String? note;

  /// 整节媒体的 hash（'m'）。只有这一节自己换过整节媒体时才写，平时继承 chapter/book 的。
  /// 见 [VerseField.findSectionDownload]。
  String? mediaHash;

  /// 一节可以挂多条提示，下标就是提示 tab 的顺序。空条目也要占着位置，不能压缩掉。
  List<VerseTipContent> tips;
  String? question;
  String? answer;
  int? learnDate;
  int? progress;

  /// 第 1 条提示的正文。多条提示的场景请直接用 [tips]。
  String? get tip => tips.isEmpty ? null : tips.first.text;

  // 字段专属媒体（'q'/'a'/'t' 块里的 'mediaHash'）：某个字段用自己的音视频文件，
  // 而不是整节的 'd'。比如问题来自章节的视频、答案是扩展助手另外生成的音频。
  // 存的是 hash，文件对象在某一层的 'd' 里，用 VerseField.findDownloadByHash 取。
  String? questionMediaHash;
  String? answerMediaHash;

  // 字段专属视图类型（'q'/'a'/'t' 块里的 'showType'）：整节的 's' 是 q/a 共用的，
  // 一节里 q 是视频、a 是音频时必须各记各的，不能靠改 's' 来表达。
  String? questionShowType;
  String? answerShowType;

  // 各字段在媒体里的时间区间（'q'/'a'/'t' 块里的 'start'/'end'）。
  String? questionStart;
  String? questionEnd;
  String? answerStart;
  String? answerEnd;

  VerseContent({
    required this.id,
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.note,
    required this.tips,
    required this.question,
    required this.answer,
    required this.learnDate,
    required this.progress,
    this.mediaHash,
    this.questionMediaHash,
    this.answerMediaHash,
    this.questionShowType,
    this.answerShowType,
    this.questionStart,
    this.questionEnd,
    this.answerStart,
    this.answerEnd,
  });

  factory VerseContent.fromJson(Map<String, dynamic> json) {
    final tips = <VerseTipContent>[];
    for (var i = 0; i < VerseField.tipLength(json); i++) {
      final r = VerseField.ref('t', i);
      tips.add(VerseTipContent(
        text: VerseField.getText(json, r),
        mediaHash: VerseField.getStr(json, r, VerseField.mediaHash),
        showType: VerseField.getStr(json, r, VerseField.showType),
        start: VerseField.getStr(json, r, VerseField.start),
        end: VerseField.getStr(json, r, VerseField.end),
      ));
    }
    return VerseContent(
      id: json['i'] as int?,
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      mediaHash: json[VerseField.sectionMediaHash] as String?,
      note: VerseField.getText(json, 'n'),
      tips: tips,
      question: VerseField.getText(json, 'q'),
      answer: VerseField.getText(json, 'a'),
      learnDate: json['l'] as int?,
      progress: json['p'] as int?,
      questionMediaHash: VerseField.getStr(json, 'q', VerseField.mediaHash),
      answerMediaHash: VerseField.getStr(json, 'a', VerseField.mediaHash),
      questionShowType: VerseField.getStr(json, 'q', VerseField.showType),
      answerShowType: VerseField.getStr(json, 'a', VerseField.showType),
      questionStart: VerseField.getStr(json, 'q', VerseField.start),
      questionEnd: VerseField.getStr(json, 'q', VerseField.end),
      answerStart: VerseField.getStr(json, 'a', VerseField.start),
      answerEnd: VerseField.getStr(json, 'a', VerseField.end),
    );
  }

  Map<String, dynamic> toJson() {
    final ret = <String, dynamic>{
      'i': id,
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      'l': learnDate,
      'p': progress,
      if (mediaHash != null) VerseField.sectionMediaHash: mediaHash,
    };
    VerseField.setText(ret, 'n', note);
    // 字段块里的每一项都只在有的时候才写，避免给老内容凭空加上一堆 null。
    _fieldToJson(ret, 'q', question, questionMediaHash, questionShowType, questionStart, questionEnd);
    _fieldToJson(ret, 'a', answer, answerMediaHash, answerShowType, answerStart, answerEnd);
    // 从最后一条往前写：先写下标大的，中间的空条目才会被 _ensure 补齐占位，
    // 不然「第 1 条空、第 2 条有内容」会被压成一条。
    for (var i = tips.length - 1; i >= 0; i--) {
      final t = tips[i];
      if (t.isEmpty) {
        continue;
      }
      _fieldToJson(ret, VerseField.ref('t', i), t.text, t.mediaHash, t.showType, t.start, t.end);
    }
    return ret;
  }

  static void _fieldToJson(
    Map<String, dynamic> ret,
    String acronym,
    String? text,
    String? mediaHash,
    String? showType,
    String? start,
    String? end,
  ) {
    VerseField.setText(ret, acronym, text);
    VerseField.setStr(ret, acronym, VerseField.mediaHash, mediaHash);
    VerseField.setStr(ret, acronym, VerseField.showType, showType);
    VerseField.setStr(ret, acronym, VerseField.start, start);
    VerseField.setStr(ret, acronym, VerseField.end, end);
  }
}
