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

  /// 字段专属媒体在 verse 内容里的 key，跟 'aStart'/'aEnd' 一套命名：'a' -> 'aDownload'。
  /// 值是单个 DownloadContent（不是列表）：这个字段的音视频就是这一个文件，
  /// 它的 'aStart'/'aEnd' 也是相对这个文件的时间。没有这个 key 时沿用整节的 'd'。
  static String fieldKey(String acronym) => "${acronym}Download";

  static const List<String> fieldKeys = ['qDownload', 'aDownload', 'tDownload'];

  static List<DownloadContent>? toList(dynamic json) {
    if (json != null) {
      return (json as List).map((e) => DownloadContent.fromJson(e as Map<String, dynamic>)).toList();
    }
    return null;
  }

  /// 一层内容（book/chapter/verse 的 map）里的全部媒体：整层的 'd' 列表 + 字段专属媒体。
  static List<DownloadContent> allOf(Map<String, dynamic> json) {
    final ret = <DownloadContent>[];
    ret.addAll(toList(json['d']) ?? []);
    for (var key in fieldKeys) {
      final d = fromJsonOrNull(json[key]);
      if (d != null) {
        ret.add(d);
      }
    }
    return ret;
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

  // 字段专属媒体（'qDownload'/'aDownload'/'tDownload'）：某个字段用自己的音视频文件，
  // 而不是整节的 'd'。比如问题来自章节的视频、答案是扩展助手另外生成的音频。
  DownloadContent? questionDownload;
  DownloadContent? answerDownload;
  DownloadContent? tipDownload;

  // 字段专属视图类型（'qShowType'/'aShowType'/'tShowType'）：整节的 's' 是 q/a 共用的，
  // 一节里 q 是视频、a 是音频时必须各记各的，不能靠改 's' 来表达。
  String? questionShowType;
  String? answerShowType;
  String? tipShowType;

  /// 字段专属视图类型的 key：'a' -> 'aShowType'。
  static String fieldShowTypeKey(String acronym) => "${acronym}ShowType";

  static const List<String> fieldShowTypeKeys = ['qShowType', 'aShowType', 'tShowType'];

  List<DownloadContent> get fieldDownloads => [questionDownload, answerDownload, tipDownload].whereType<DownloadContent>().toList();

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
    this.questionDownload,
    this.answerDownload,
    this.tipDownload,
    this.questionShowType,
    this.answerShowType,
    this.tipShowType,
  });

  factory VerseContent.fromJson(Map<String, dynamic> json) {
    return VerseContent(
      id: json['i'] as int?,
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      key: json['k'] as String?,
      write: json['w'] as String?,
      note: json['n'] as String?,
      tip: json['t'] as String?,
      question: json['q'] as String?,
      answer: json['a'] as String?,
      learnDate: json['l'] as int?,
      progress: json['p'] as int?,
      questionDownload: DownloadContent.fromJsonOrNull(json[DownloadContent.fieldKey('q')]),
      answerDownload: DownloadContent.fromJsonOrNull(json[DownloadContent.fieldKey('a')]),
      tipDownload: DownloadContent.fromJsonOrNull(json[DownloadContent.fieldKey('t')]),
      questionShowType: json[VerseContent.fieldShowTypeKey('q')] as String?,
      answerShowType: json[VerseContent.fieldShowTypeKey('a')] as String?,
      tipShowType: json[VerseContent.fieldShowTypeKey('t')] as String?,
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
      'n': note,
      't': tip,
      'q': question,
      'a': answer,
      'l': learnDate,
      'p': progress,
    };
    // 字段专属媒体只在有的时候才写，避免给老内容凭空加上一堆 null。
    if (questionDownload != null) {
      ret[DownloadContent.fieldKey('q')] = questionDownload!.toJson();
    }
    if (answerDownload != null) {
      ret[DownloadContent.fieldKey('a')] = answerDownload!.toJson();
    }
    if (tipDownload != null) {
      ret[DownloadContent.fieldKey('t')] = tipDownload!.toJson();
    }
    if (questionShowType != null) {
      ret[fieldShowTypeKey('q')] = questionShowType;
    }
    if (answerShowType != null) {
      ret[fieldShowTypeKey('a')] = answerShowType;
    }
    if (tipShowType != null) {
      ret[fieldShowTypeKey('t')] = tipShowType;
    }
    return ret;
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
