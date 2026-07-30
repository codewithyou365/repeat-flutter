class BookContent {
  String? showType;
  String? rootUrl;
  List<DownloadContent>? download;
  List<ChapterContent> chapter;

  BookContent({
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.chapter,
  });

  factory BookContent.fromJson(Map<String, dynamic> json) {
    return BookContent(
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      chapter: (json['c'] as List?)?.map((e) => ChapterContent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
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
  List<VerseContent> verse;

  ChapterContent({
    required this.id,
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.verse,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      id: json['i'] as int?,
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      verse: (json['v'] as List?)?.map((e) => VerseContent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'i': id,
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
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
///   没有 mediaHash 时沿用整节的 'd'。
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
/// book 那一层的字段块里还放着字体（'fontSize'/'fontAlias'/'fontHash'，四个字段都有，
/// 包括 'n'）。注意 book 的 't' 块同时还是提示配置（按 'a'/'q'/'t'/'n' 分的子 map），
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

  /// verse 一层有嵌套字段块的字段（QaType 里只有 'n' 例外，它的正文是平铺的）。
  static const List<String> acronyms = ['q', 'a', 't'];

  static bool nested(String acronym) => acronyms.contains(acronym);

  /// 字段块本身，没有就返回 null（不会顺手建出来）。
  static Map<String, dynamic>? of(Map<String, dynamic> content, String acronym) {
    final ret = content[acronym];
    if (ret is Map<String, dynamic>) {
      return ret;
    }
    return null;
  }

  static Map<String, dynamic> _ensure(Map<String, dynamic> content, String acronym) {
    var ret = of(content, acronym);
    if (ret == null) {
      ret = <String, dynamic>{};
      content[acronym] = ret;
    }
    return ret;
  }

  static String? getStr(Map<String, dynamic> content, String acronym, String key) {
    final v = of(content, acronym)?[key];
    if (v is String && v.isNotEmpty) {
      return v;
    }
    return null;
  }

  /// 传 null 或空串就把这个 key 删掉；删完字段块空了连块一起删，避免留下一堆 `'t': {}`。
  static void setStr(Map<String, dynamic> content, String acronym, String key, String? value) {
    if (value == null || value.isEmpty) {
      remove(content, acronym, [key]);
      return;
    }
    _ensure(content, acronym)[key] = value;
  }

  static void remove(Map<String, dynamic> content, String acronym, List<String> keys) {
    final field = of(content, acronym);
    if (field == null) {
      return;
    }
    for (var key in keys) {
      field.remove(key);
    }
    if (field.isEmpty) {
      content.remove(acronym);
    }
  }

  /// 正文。'n'（笔记）没有字段块，直接平铺存。
  static String? getText(Map<String, dynamic> content, String acronym) {
    if (!nested(acronym)) {
      final v = content[acronym];
      return v is String && v.isNotEmpty ? v : null;
    }
    return getStr(content, acronym, text);
  }

  static void setText(Map<String, dynamic> content, String acronym, String? value) {
    if (!nested(acronym)) {
      if (value == null || value.isEmpty) {
        content.remove(acronym);
      } else {
        content[acronym] = value;
      }
      return;
    }
    setStr(content, acronym, text, value);
  }

  /// 逐层找一个字段属性：verse -> chapter -> book，第一个有值的算数。
  /// contents 按由近到远传（null 的层跳过）。
  static String? lookup(List<Map<String, dynamic>?> contents, String acronym, String key) {
    for (var content in contents) {
      if (content == null) {
        continue;
      }
      final v = getStr(content, acronym, key);
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

  /// 给某个字段挂一份专属媒体：文件对象登记进 'd'，字段块里只写 mediaHash。
  ///
  /// 就近登记：verse 本来就有 'd' 就追加到 verse，否则登记到 book（跟字体一个地方）——
  /// 在原本没有 'd' 的 verse 上凭空造一个 'd'，会把这一节的整节媒体顶成这个文件。
  /// 返回 book 那一层是不是被改了，改了的话调用方要把 book 也写回数据库。
  static bool setMedia({
    required Map<String, dynamic> verse,
    required Map<String, dynamic>? book,
    required String acronym,
    required DownloadContent d,
  }) {
    var bookChanged = false;
    if (verse['d'] != null || book == null) {
      addDownload(verse, d);
    } else {
      bookChanged = addDownload(book, d);
    }
    setStr(verse, acronym, mediaHash, d.hash);
    return bookChanged;
  }

  /// 把文件对象登记进这一层的 'd' 列表（按 hash 去重）。
  /// 一定是追加：'d' 的第一项是整节媒体，插到前面会把整节的音视频换掉。
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

class VerseContent {
  int? id;
  String? showType;
  String? rootUrl;
  List<DownloadContent>? download;
  String? key;
  String? write;
  String? note;
  String? tip;
  String? question;
  String? answer;
  int? learnDate;
  int? progress;

  // 字段专属媒体（'q'/'a'/'t' 块里的 'mediaHash'）：某个字段用自己的音视频文件，
  // 而不是整节的 'd'。比如问题来自章节的视频、答案是扩展助手另外生成的音频。
  // 存的是 hash，文件对象在某一层的 'd' 里，用 VerseField.findDownloadByHash 取。
  String? questionMediaHash;
  String? answerMediaHash;
  String? tipMediaHash;

  // 字段专属视图类型（'q'/'a'/'t' 块里的 'showType'）：整节的 's' 是 q/a 共用的，
  // 一节里 q 是视频、a 是音频时必须各记各的，不能靠改 's' 来表达。
  String? questionShowType;
  String? answerShowType;
  String? tipShowType;

  // 各字段在媒体里的时间区间（'q'/'a'/'t' 块里的 'start'/'end'）。
  String? questionStart;
  String? questionEnd;
  String? answerStart;
  String? answerEnd;
  String? tipStart;
  String? tipEnd;

  VerseContent({
    required this.id,
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.key,
    required this.write,
    required this.note,
    required this.tip,
    required this.question,
    required this.answer,
    required this.learnDate,
    required this.progress,
    this.questionMediaHash,
    this.answerMediaHash,
    this.tipMediaHash,
    this.questionShowType,
    this.answerShowType,
    this.tipShowType,
    this.questionStart,
    this.questionEnd,
    this.answerStart,
    this.answerEnd,
    this.tipStart,
    this.tipEnd,
  });

  factory VerseContent.fromJson(Map<String, dynamic> json) {
    return VerseContent(
      id: json['i'] as int?,
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      key: json['k'] as String?,
      write: json['w'] as String?,
      note: VerseField.getText(json, 'n'),
      tip: VerseField.getText(json, 't'),
      question: VerseField.getText(json, 'q'),
      answer: VerseField.getText(json, 'a'),
      learnDate: json['l'] as int?,
      progress: json['p'] as int?,
      questionMediaHash: VerseField.getStr(json, 'q', VerseField.mediaHash),
      answerMediaHash: VerseField.getStr(json, 'a', VerseField.mediaHash),
      tipMediaHash: VerseField.getStr(json, 't', VerseField.mediaHash),
      questionShowType: VerseField.getStr(json, 'q', VerseField.showType),
      answerShowType: VerseField.getStr(json, 'a', VerseField.showType),
      tipShowType: VerseField.getStr(json, 't', VerseField.showType),
      questionStart: VerseField.getStr(json, 'q', VerseField.start),
      questionEnd: VerseField.getStr(json, 'q', VerseField.end),
      answerStart: VerseField.getStr(json, 'a', VerseField.start),
      answerEnd: VerseField.getStr(json, 'a', VerseField.end),
      tipStart: VerseField.getStr(json, 't', VerseField.start),
      tipEnd: VerseField.getStr(json, 't', VerseField.end),
    );
  }

  Map<String, dynamic> toJson() {
    final ret = <String, dynamic>{
      'i': id,
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      'k': key,
      'w': write,
      'l': learnDate,
      'p': progress,
    };
    VerseField.setText(ret, 'n', note);
    // 字段块里的每一项都只在有的时候才写，避免给老内容凭空加上一堆 null。
    _fieldToJson(ret, 'q', question, questionMediaHash, questionShowType, questionStart, questionEnd);
    _fieldToJson(ret, 'a', answer, answerMediaHash, answerShowType, answerStart, answerEnd);
    _fieldToJson(ret, 't', tip, tipMediaHash, tipShowType, tipStart, tipEnd);
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

class OtherVerseContent {
  List<VerseReviewContent> verseReviewContent;

  OtherVerseContent({
    required this.verseReviewContent,
  });

  factory OtherVerseContent.fromJson(Map<String, dynamic> json) {
    return OtherVerseContent(
      verseReviewContent: (json['verseReviewContent'] as List?)?.map((e) => VerseReviewContent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verseReviewContent': verseReviewContent,
    };
  }
}

class VerseReviewContent {
  int createDate;
  int count;

  VerseReviewContent({
    required this.createDate,
    required this.count,
  });

  factory VerseReviewContent.fromJson(Map<String, dynamic> json) {
    return VerseReviewContent(
      createDate: json['createDate'] as int,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createDate': createDate,
      'count': count,
    };
  }
}
