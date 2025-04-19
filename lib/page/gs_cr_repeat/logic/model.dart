import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'helper.dart';

class Range {
  int start;
  int end;
  bool enable;

  Range({
    required this.start,
    required this.end,
    required this.enable,
  });
}

class MediaSegmentHelper {
  Map<int, MediaSegment> mediaSegmentCache = {};
  Map<int, Range> answerRangeCache = {};
  Map<int, Range> questionRangeCache = {};
  final Helper helper;

  MediaSegmentHelper({
    required this.helper,
  });

  MediaSegment? getMediaSegment() {
    if (helper.logic.currSegment == null) {
      return null;
    }
    MediaSegment? ret = mediaSegmentCache[helper.logic.currSegment!.segmentKeyId];
    if (ret != null) {
      return ret;
    }
    final map = helper.getCurrSegmentMap();
    if (map == null) {
      return null;
    }
    ret = MediaSegment.fromJson(map);
    mediaSegmentCache[helper.logic.currSegment!.segmentKeyId] = ret;
    return ret;
  }

  Range? getCurrAnswerRange() {
    if (helper.logic.currSegment == null) {
      return null;
    }
    Range? ret = answerRangeCache[helper.logic.currSegment!.segmentKeyId];
    if (ret != null) {
      return ret;
    }
    final s = getMediaSegment();
    if (s == null) {
      return null;
    }
    if (s.aStart != null && //
        s.aEnd != null &&
        s.aStart!.isNotEmpty &&
        s.aEnd!.isNotEmpty) {
      final start = Time.parseTimeToMilliseconds(s.aStart!).toInt();
      final end = Time.parseTimeToMilliseconds(s.aEnd!).toInt();
      ret = Range(start: start, end: end, enable: true);
      answerRangeCache[helper.logic.currSegment!.segmentKeyId] = ret;
    } else {
      ret = Range(start: 0, end: 0, enable: false);
      answerRangeCache[helper.logic.currSegment!.segmentKeyId] = ret;
    }
    return ret;
  }

  Range? getCurrQuestionRange() {
    if (helper.logic.currSegment == null) {
      return null;
    }
    Range? ret = questionRangeCache[helper.logic.currSegment!.segmentKeyId];
    if (ret != null) {
      return ret;
    }
    final s = getMediaSegment();
    if (s == null) {
      return null;
    }
    if (s.qStart != null && //
        s.qEnd != null &&
        s.qStart!.isNotEmpty &&
        s.qEnd!.isNotEmpty) {
      final start = Time.parseTimeToMilliseconds(s.qStart!).toInt();
      final end = Time.parseTimeToMilliseconds(s.qEnd!).toInt();
      ret = Range(start: start, end: end, enable: true);
      questionRangeCache[helper.logic.currSegment!.segmentKeyId] = ret;
    } else {
      ret = Range(start: 0, end: 0, enable: false);
      questionRangeCache[helper.logic.currSegment!.segmentKeyId] = ret;
    }
    return ret;
  }
}

class MediaSegment extends Segment {
  String? qStart;
  String? qEnd;
  String? aStart;
  String? aEnd;

  MediaSegment({
    required super.view,
    required super.rootUrl,
    required super.download,
    required super.key,
    required super.write,
    required super.note,
    required super.tip,
    required super.question,
    required super.answer,
    required this.qStart,
    required this.qEnd,
    required this.aStart,
    required this.aEnd,
  });

  factory MediaSegment.fromJson(Map<String, dynamic> json) {
    return MediaSegment(
      view: json['v'] as String?,
      rootUrl: json['r'] as String?,
      download: Download.toList(json['d']),
      key: json['k'] as String?,
      write: json['w'] as String?,
      note: json['n'] as String?,
      tip: json['t'] as String?,
      question: json['q'] as String?,
      answer: json['a'] as String,
      qStart: json['qStart'] as String?,
      qEnd: json['qEnd'] as String?,
      aStart: json['aStart'] as String?,
      aEnd: json['aEnd'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'v': super.view,
      'r': super.rootUrl,
      'd': super.download?.map((e) => e.toJson()).toList(),
      'k': super.key,
      'w': super.write,
      'n': super.note,
      't': super.tip,
      'q': super.question,
      'a': super.answer,
      'qStart': qStart,
      'qEnd': qEnd,
      'aStart': aStart,
      'aEnd': aEnd,
    };
  }
}
