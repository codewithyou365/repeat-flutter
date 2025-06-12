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

  String get extension => url.split('.').last;

  String get folder => hash.substring(0, 2);

  String get name => "${hash.substring(2)}.$extension";

  String get path => "$folder/$name";

  DownloadContent({
    required this.url,
    required this.hash,
  });

  static List<DownloadContent>? toList(dynamic json) {
    if (json != null) {
      return (json as List).map((e) => DownloadContent.fromJson(e as Map<String, dynamic>)).toList();
    }
    return null;
  }

  factory DownloadContent.fromJson(Map<String, dynamic> json) {
    return DownloadContent(
      url: json['u'] as String,
      hash: json['h'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'u': url,
      'h': hash,
    };
  }
}

class ChapterContent {
  String? showType;
  String? rootUrl;
  List<DownloadContent>? download;
  List<VerseContent> verse;

  ChapterContent({
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.verse,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      verse: (json['v'] as List?)?.map((e) => VerseContent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      'v': verse.map((e) => e.toJson()).toList(),
    };
  }
}

class VerseContent {
  String? showType;
  String? rootUrl;
  List<DownloadContent>? download;
  String? key;
  String? write;
  String? note;
  String? tip;
  String? question;
  String answer;

  VerseContent({
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.key,
    required this.write,
    required this.note,
    required this.tip,
    required this.question,
    required this.answer,
  });

  factory VerseContent.fromJson(Map<String, dynamic> json) {
    return VerseContent(
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: DownloadContent.toList(json['d']),
      key: json['k'] as String?,
      write: json['w'] as String?,
      note: json['n'] as String?,
      tip: json['t'] as String?,
      question: json['q'] as String?,
      answer: json['a'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      'k': key,
      'w': write,
      'n': note,
      't': tip,
      'q': question,
      'a': answer,
    };
  }
}
