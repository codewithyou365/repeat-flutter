class RepeatDoc {
  String? showType;
  String? rootUrl;
  List<Download>? download;
  List<Lesson> lesson;

  RepeatDoc({
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.lesson,
  });

  factory RepeatDoc.fromJson(Map<String, dynamic> json) {
    return RepeatDoc(
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: Download.toList(json['d']),
      lesson: (json['l'] as List?)?.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      's': showType,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      'l': lesson.map((e) => e.toJson()).toList(),
    };
  }
}

class Download {
  String url;
  String hash;

  String get extension => url.split('.').last;

  String get folder => hash.substring(0, 2);

  String get name => "${hash.substring(2)}.$extension";

  String get path => "$folder/$name";

  Download({
    required this.url,
    required this.hash,
  });

  static List<Download>? toList(dynamic json) {
    if (json != null) {
      return (json as List).map((e) => Download.fromJson(e as Map<String, dynamic>)).toList();
    }
    return null;
  }

  factory Download.fromJson(Map<String, dynamic> json) {
    return Download(
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

class Lesson {
  String? showType;
  String? rootUrl;
  List<Download>? download;
  List<Verse> verse;

  Lesson({
    required this.showType,
    required this.rootUrl,
    required this.download,
    required this.verse,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: Download.toList(json['d']),
      verse: (json['v'] as List?)?.map((e) => Verse.fromJson(e as Map<String, dynamic>)).toList() ?? [],
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

class Verse {
  String? showType;
  String? rootUrl;
  List<Download>? download;
  String? key;
  String? write;
  String? note;
  String? tip;
  String? question;
  String answer;

  Verse({
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

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      showType: json['s'] as String?,
      rootUrl: json['r'] as String?,
      download: Download.toList(json['d']),
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
