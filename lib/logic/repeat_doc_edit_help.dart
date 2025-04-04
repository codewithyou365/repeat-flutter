import 'dart:convert';

import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

import 'model/repeat_doc.dart';

enum PlayType { none, question, answer }

enum EditType {
  setHead,
  setTail,
  extendTail,
  cut,
  deleteCurr,
}

class SegmentEditHelpOutArg {
  int segmentCount;

  SegmentEditHelpOutArg(this.segmentCount);
}

class RepeatDocEditHelp {
  static Future<bool> setVideoMaskRatio(
    SegmentContent ret,
    double ratio, {
    SegmentEditHelpOutArg? out,
  }) async {
    Map<String, dynamic>? map = await RepeatDocHelp.getAndCacheJsonQa(ret.contentSerial);
    if (map == null) {
      return false;
    }

    List<dynamic> lessons = List<dynamic>.from(map['lesson']);
    map['lesson'] = lessons;
    Map<String, dynamic> lesson = Map<String, dynamic>.from(lessons[ret.lessonIndex]);
    lessons[ret.lessonIndex] = lesson;
    lesson['videoMaskRatio'] = "$ratio";
    var indexPath = DocPath.getRelativeIndexPath(ret.contentSerial);
    await RepeatDoc.writeFile(indexPath, map);
    RepeatDocHelp.setVideoMaskRatio(ret.contentSerial, ret.lessonIndex, ret.mediaExtension, ratio);
    return true;
  }

  static Future<bool> edit(
    SegmentContent ret,
    EditType editType,
    PlayType playType,
    Duration position,
    Duration duration, {
    SegmentEditHelpOutArg? out,
  }) async {
    var indexPath = DocPath.getRelativeIndexPath(ret.contentSerial);
    Map<String, dynamic>? map = await RepeatDocHelp.getAndCacheJsonQa(ret.contentSerial);
    if (map == null) {
      return false;
    }

    List<dynamic> lessons = List<dynamic>.from(map['lesson']);
    map['lesson'] = lessons;
    Map<String, dynamic> lesson = Map<String, dynamic>.from(lessons[ret.lessonIndex]);
    lessons[ret.lessonIndex] = lesson;
    List<dynamic> segments = List<dynamic>.from(lesson['segment']);
    lesson['segment'] = segments;
    if (out != null) {
      out.segmentCount = segments.length;
    }
    Map<String, String> segment = Map<String, String>.from(segments[ret.segmentIndex]);
    segments[ret.segmentIndex] = segment;

    switch (editType) {
      case EditType.setHead:
        switch (playType) {
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
          case PlayType.question:
            segment['qEnd'] = Time.extend(segment['qEnd']!, 10000, duration);
            ret.qMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['qStart']!, segment['qEnd']!);
            break;
          case PlayType.answer:
            segment['aEnd'] = Time.extend(segment['aEnd']!, 10000, duration);
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
          case PlayType.question:
            segment['qEnd'] = splitPoint;
            newSegment['qStart'] = splitPoint;
            segments.insert(ret.segmentIndex + 1, newSegment);
            ret.qMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['qStart']!, segment['qEnd']!);
            break;
          case PlayType.answer:
            segment['aEnd'] = splitPoint;
            newSegment['aStart'] = splitPoint;
            segments.insert(ret.segmentIndex + 1, newSegment);
            ret.aMediaSegments[ret.segmentIndex] = MediaSegment.from(segment['aStart']!, segment['aEnd']!);
            break;
          default:
            return false;
        }
        break;
      case EditType.deleteCurr:
        switch (playType) {
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
    await RepeatDoc.writeFile(indexPath, map);
    RepeatDocHelp.clear();
    return true;
  }

  static Future<String?> getSegment(int contentSerial, int lessonIndex, int segmentIndex, [format = false]) async {
    var map = await RepeatDocHelp.getAndCacheJsonQa(contentSerial);
    if (map == null) {
      return null;
    }
    List<dynamic> lessons = List<dynamic>.from(map['lesson']);
    if (lessonIndex >= lessons.length) {
      return null;
    }
    List<dynamic> segments = List<dynamic>.from(lessons[lessonIndex]['segment']);
    if (segmentIndex >= segments.length) {
      return null;
    }
    if (format) {
      return const JsonEncoder.withIndent(' ').convert(segments[segmentIndex]);
    } else {
      return jsonEncode(segments[segmentIndex]);
    }
  }

  static Future<bool> setSegment(int contentSerial, int lessonIndex, int segmentIndex, String body) async {
    var map = await RepeatDocHelp.getAndCacheJsonQa(contentSerial);
    if (map == null) {
      return false;
    }
    List<dynamic> lessons = List<dynamic>.from(map['lesson']);
    if (lessonIndex >= lessons.length) {
      return false;
    }
    map['lesson'] = lessons;
    List<dynamic> segments = List<dynamic>.from(lessons[lessonIndex]['segment']);
    if (segmentIndex >= segments.length) {
      return false;
    }
    lessons[lessonIndex]['segment'] = segments;
    segments[segmentIndex] = jsonDecode(body);
    var indexPath = DocPath.getRelativeIndexPath(contentSerial);
    await RepeatDoc.writeFile(indexPath, map);
    RepeatDocHelp.clear();
    //await Get.find<GsCrRepeatLogic>().refreshView();
    return true;
  }
}
