import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

import 'model/repeat_doc.dart';

enum PlayType { none, question, answer, title }

enum EditType {
  setHead,
  setTail,
  extendTail,
  cut,
  deleteCurr,
}

class SegmentEditHelp {
  static Future<bool> edit(
    SegmentContent ret,
    EditType editType,
    PlayType playType,
    Duration position,
    Duration duration,
  ) async {
    Map<String, dynamic>? map = await RepeatDoc.toJsonMap(ret.indexDocPath);
    if (map == null) {
      return false;
    }

    List<dynamic> lessons = List<dynamic>.from(map['lesson']);
    map['lesson'] = lessons;
    Map<String, dynamic> lesson = Map<String, dynamic>.from(lessons[ret.lessonIndex]);
    lessons[ret.lessonIndex] = lesson;
    List<dynamic> segments = List<dynamic>.from(lesson['segment']);
    lesson['segment'] = segments;
    Map<String, String> segment = Map<String, String>.from(segments[ret.segmentIndex]);
    segments[ret.segmentIndex] = segment;

    switch (editType) {
      case EditType.setHead:
        switch (playType) {
          case PlayType.title:
            var millisecond = Time.parseTimeToMilliseconds(lesson['titleEnd']!).toInt();
            if (millisecond < position.inMilliseconds) {
              return false;
            }
            lesson['titleStart'] = Time.convertToString(position);
            ret.titleMediaSegment = MediaSegment.from(lesson['titleStart'], lesson['titleEnd']);
            break;
          case PlayType.question:
            var millisecond = Time.parseTimeToMilliseconds(segment['qEnd']!).toInt();
            if (millisecond < position.inMilliseconds) {
              return false;
            }
            segment['qStart'] = Time.convertToString(position);
            ret.qMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['qStart']!, segment['qEnd']!);

            break;
          case PlayType.answer:
            var millisecond = Time.parseTimeToMilliseconds(segment['aEnd']!).toInt();
            if (millisecond < position.inMilliseconds) {
              return false;
            }
            segment['aStart'] = Time.convertToString(position);
            ret.aMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['aStart']!, segment['aEnd']!);
            break;
          default:
            return false;
        }
        break;
      case EditType.setTail:
        switch (playType) {
          case PlayType.title:
            var millisecond = Time.parseTimeToMilliseconds(lesson['titleStart']!).toInt();
            if (position.inMilliseconds < millisecond) {
              return false;
            }
            lesson['titleEnd'] = Time.convertToString(position);
            ret.titleMediaSegment = MediaSegment.from(lesson['titleStart'], lesson['titleEnd']);
            break;
          case PlayType.question:
            var millisecond = Time.parseTimeToMilliseconds(segment['qStart']!).toInt();
            if (position.inMilliseconds < millisecond) {
              return false;
            }
            segment['qEnd'] = Time.convertToString(position);
            ret.qMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['qStart']!, segment['qEnd']!);
            break;
          case PlayType.answer:
            var millisecond = Time.parseTimeToMilliseconds(segment['aStart']!).toInt();
            if (position.inMilliseconds < millisecond) {
              return false;
            }
            segment['aEnd'] = Time.convertToString(position);
            ret.aMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['aStart']!, segment['aEnd']!);
            break;
          default:
            return false;
        }
        break;
      case EditType.extendTail:
        switch (playType) {
          case PlayType.title:
            lesson['titleEnd'] = Time.extend(lesson['titleEnd'], 1000, duration);
            ret.titleMediaSegment = MediaSegment.from(lesson['titleStart'], lesson['titleEnd']);
            break;
          case PlayType.question:
            segment['qEnd'] = Time.extend(segment['qEnd']!, 1000, duration);
            ret.qMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['qStart']!, segment['qEnd']!);
            break;
          case PlayType.answer:
            segment['aEnd'] = Time.extend(segment['aEnd']!, 1000, duration);
            ret.aMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['aStart']!, segment['aEnd']!);
            break;
          default:
            return false;
        }
        break;
      case EditType.cut:
        var splitPoint = Time.convertToString(position);
        Map<String, String> newSegment = Map.from(segment);
        switch (playType) {
          case PlayType.title:
            return false;
          case PlayType.question:
            segment['qEnd'] = splitPoint;
            newSegment['qStart'] = splitPoint;
            segments.insert(ret.segmentIndex, newSegment);
            ret.qMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['qStart']!, segment['qEnd']!);
            break;
          case PlayType.answer:
            segment['aEnd'] = splitPoint;
            newSegment['aStart'] = splitPoint;
            segments.insert(ret.segmentIndex, newSegment);
            ret.aMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['aStart']!, segment['aEnd']!);
            break;
          default:
            return false;
        }
        break;
      case EditType.deleteCurr:
        switch (playType) {
          case PlayType.title:
            return false;
          case PlayType.question:
            if (segments.length == 1) {
              return false;
            }
            segments.removeAt(ret.segmentIndex);
            ret.qMediaSegments.removeAt(ret.segmentIndex);
            break;
          case PlayType.answer:
            if (segments.length == 1) {
              return false;
            }
            segments.removeAt(ret.segmentIndex);
            ret.aMediaSegments.removeAt(ret.segmentIndex);
            break;
          default:
            return false;
        }
        break;
      default:
        return false;
    }
    RepeatDoc.writeFile(ret.indexDocPath, map);
    SegmentHelp.clear();
    return true;
  }
}
