import 'package:repeat_flutter/common/path.dart';

class RepeatDoc {
  String? view;
  String? rootUrl;
  List<Download>? download;
  List<Lesson> lesson;

  RepeatDoc({
    required this.view,
    required this.rootUrl,
    required this.download,
    required this.lesson,
  });

  factory RepeatDoc.fromJson(Map<String, dynamic> json) {
    return RepeatDoc(
      view: json['v'] as String?,
      rootUrl: json['r'] as String?,
      download: json['d'] != null ? (json['d'] as List).map((e) => Download.fromJson(e as Map<String, dynamic>)).toList() : null,
      lesson: (json['l'] as List).map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'v': view,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      'l': lesson.map((e) => e.toJson()).toList(),
    };
  }
}

class Download {
  String url;
  String hash;

  String get path => hash.substring(0, 2).joinPath("${hash.substring(2)}.${url.split('.').last}");

  Download({
    required this.url,
    required this.hash,
  });

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
  String? view;
  String? rootUrl;
  List<Download>? download;
  List<Segment> segment;

  Lesson({
    required this.view,
    required this.rootUrl,
    required this.download,
    required this.segment,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      view: json['v'] as String?,
      rootUrl: json['r'] as String?,
      download: json['d'] != null ? (json['d'] as List).map((e) => Download.fromJson(e as Map<String, dynamic>)).toList() : null,
      segment: (json['s'] as List).map((e) => Segment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'v': view,
      'r': rootUrl,
      'd': download?.map((e) => e.toJson()).toList(),
      's': segment.map((e) => e.toJson()).toList(),
    };
  }
}

class Segment {
  String? view;
  String? rootUrl;
  List<Download>? download;
  String? key;
  String? write;
  String? note;
  String? tip;
  String? question;
  String answer;

  Segment({
    required this.view,
    required this.rootUrl,
    required this.download,
    required this.key,
    required this.write,
    required this.note,
    required this.tip,
    required this.question,
    required this.answer,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      view: json['v'] as String?,
      rootUrl: json['r'] as String?,
      download: json['d'] != null ? (json['d'] as List).map((e) => Download.fromJson(e as Map<String, dynamic>)).toList() : null,
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
      'v': view,
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
