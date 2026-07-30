import 'dart:convert';

import 'package:repeat_flutter/logic/model/book_content.dart';

/// Dart port of `example/srt.go`. Keep in sync with the Go source if that file changes;
/// the mode marker line, the offset%3 cue-cycle, and the post-processing padding order
/// are all faithfully mirrored, not just approximated.
class SrtSegment {
  String? qStart;
  String? qEnd;
  String? q;
  String? aStart;
  String? aEnd;
  String? tip;
  String? a;

  /// 直接就是一节的 verse 内容：每个字段一块 `{'text','start','end'}`（见 [VerseField]）。
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    VerseField.setStr(m, 'q', VerseField.text, q);
    VerseField.setStr(m, 'q', VerseField.start, qStart);
    VerseField.setStr(m, 'q', VerseField.end, qEnd);
    VerseField.setStr(m, 'a', VerseField.text, a);
    VerseField.setStr(m, 'a', VerseField.start, aStart);
    VerseField.setStr(m, 'a', VerseField.end, aEnd);
    VerseField.setStr(m, 't', VerseField.text, tip);
    return m;
  }
}

class SrtParse {
  static const String listenMode = 'l';
  static const String listenFullMode = 'lf';
  static const String qaMode = 'qa';
  static const String normalMode = 'n';
  static const String normalWithPerfectPunctuationMode = 'npp';

  static List<SrtSegment> parse(String content) {
    final lines = const LineSplitter().convert(content);
    int pos = 0;
    String? nextRawLine() {
      if (pos >= lines.length) return null;
      final l = lines[pos];
      pos++;
      return l;
    }

    int offset = 0;
    int modeOffset = 0;
    // Our srt files carry no mode marker on the first line; fix the parser to
    // always run in listen mode instead of detecting it from the content.
    String mode = listenMode;
    String preContent = '';
    List<String> preContentFields = [];
    int preContentIndex = 0;
    List<SrtSegment> segments = [];
    SrtSegment curr = SrtSegment();

    while (true) {
      final raw = nextRawLine();
      if (raw == null) break;
      final line = raw.trim();

      if (mode == normalWithPerfectPunctuationMode) {
        if (line != '---') {
          preContent += '$line ';
          continue;
        } else {
          preContentFields = _fields(preContent);
          mode = normalMode;
          continue;
        }
      }

      if (line.isEmpty) {
        continue;
      } else {
        if (offset % 3 == 1) {
          if (mode == listenMode || mode == listenFullMode) {
            final se = line.split('-->');
            if (curr.qStart == null || curr.qStart!.isEmpty) {
              curr.qStart = se[0].trim();
            }
            curr.qEnd = se[1].trim();
          } else if (mode == qaMode) {
            if (modeOffset % 2 == 0) {
              final se = line.split('-->');
              if (curr.qStart == null || curr.qStart!.isEmpty) {
                curr.qStart = se[0].trim();
              }
              curr.qEnd = se[1].trim();
            } else {
              final se = line.split('-->');
              if (curr.aStart == null || curr.aStart!.isEmpty) {
                curr.aStart = se[0].trim();
              }
              curr.aEnd = se[1].trim();
            }
          } else {
            final se = line.split('-->');
            if (curr.aStart == null || curr.aStart!.isEmpty) {
              curr.aStart = se[0].trim();
            }
            curr.aEnd = se[1].trim();
          }
        }
        if (offset % 3 == 2) {
          if (mode == listenMode || mode == listenFullMode) {
            curr.a = line;
            while (true) {
              final rawExtra = nextRawLine();
              if (rawExtra == null) break;
              final extra = rawExtra.trim();
              if (extra.isEmpty) break;
              curr.q = '${curr.q} $extra';
            }
            segments.add(curr);
            curr = SrtSegment();
          } else if (mode == qaMode) {
            if (modeOffset % 2 == 0) {
              if (line.endsWith('|')) {
                curr.q = (curr.q ?? '') + _trimTrailingPipes(line);
              } else {
                curr.q = (curr.q ?? '') + line;
                modeOffset++;
              }
            } else {
              if (line.endsWith('|')) {
                curr.a = (curr.a ?? '') + _trimTrailingPipes(line);
              } else {
                curr.a = (curr.a ?? '') + line;
                segments.add(curr);
                curr = SrtSegment();
                modeOffset++;
              }
            }
          } else {
            if (line.endsWith('|')) {
              curr.a = (curr.a ?? '') + _trimTrailingPipes(line);
            } else {
              curr.a = (curr.a ?? '') + line;
              if (preContentFields.isNotEmpty) {
                List<String> currFields = _fields(curr.a!);
                for (int i = 0; i < currFields.length; i++) {
                  if (currFields[i] == 's' || currFields[i] == 't') {
                    currFields.removeAt(i);
                    i--;
                    continue;
                  }
                  if (i + preContentIndex < preContentFields.length && preContentFields[i + preContentIndex] != currFields[i]) {
                    currFields[i] = preContentFields[i + preContentIndex];
                  }
                }
                preContentIndex += currFields.length;
                curr.a = currFields.join(' ');
              }
              while (true) {
                final rawTip = nextRawLine();
                if (rawTip == null) break;
                final lineTip = rawTip.trim();
                if (lineTip.isEmpty) continue;
                curr.tip = lineTip;
                break;
              }
              segments.add(curr);
              curr = SrtSegment();
            }
          }
        }
        offset++;
      }
    }

    if (segments.isNotEmpty) {
      if (segments[0].aStart != null && segments[0].aStart!.isNotEmpty) {
        int millis = timeRangeToMillis(segments[0].aStart!);
        segments[0].aStart = _forStart(millis, 500);
        millis = timeRangeToMillis(segments[segments.length - 1].aEnd!);
        segments[segments.length - 1].aEnd = _forEnd(millis, 500);

        for (int i = 1; i < segments.length; i++) {
          final pe = timeRangeToMillis(segments[i - 1].aEnd!);
          final cs = timeRangeToMillis(segments[i].aStart!);
          int middleGap = (cs - pe) ~/ 2;
          middleGap -= 50;
          if (middleGap < 0) {
            continue;
          }
          if (middleGap > 500) {
            middleGap = 500;
          }
          segments[i].aStart = _forStart(cs, middleGap);
          segments[i - 1].aEnd = _forEnd(pe, middleGap);
        }
      }
      if (mode == qaMode || mode == listenMode) {
        int millis = timeRangeToMillis(segments[0].qStart!);
        segments[0].qStart = _forStart(millis, 500);
        millis = timeRangeToMillis(segments[segments.length - 1].qEnd!);
        segments[segments.length - 1].qEnd = _forEnd(millis, 500);

        for (int i = 1; i < segments.length; i++) {
          final pe = timeRangeToMillis(segments[i - 1].qEnd!);
          final cs = timeRangeToMillis(segments[i].qStart!);
          int middleGap = (cs - pe) ~/ 2;
          middleGap -= 50;
          if (middleGap < 0) {
            continue;
          }
          if (middleGap > 500) {
            middleGap = 500;
          }
          segments[i].qStart = _forStart(cs, middleGap);
          segments[i - 1].qEnd = _forEnd(pe, middleGap);
        }
      }
      const padding = 500;
      if (mode == listenFullMode) {
        final start = timeRangeToMillis(segments[0].qStart!);
        segments[0].qStart = _forStart(start, padding);

        for (int i = 1; i < segments.length; i++) {
          final prevEnd = timeRangeToMillis(segments[i - 1].qEnd!);
          final origStart = timeRangeToMillis(segments[i].qStart!);
          final origEnd = timeRangeToMillis(segments[i].qEnd!);

          int newStart = origStart - padding;
          if (newStart < prevEnd) {
            newStart = prevEnd;
          }

          segments[i].qStart = millisToTimeRange(newStart);
          segments[i].qEnd = millisToTimeRange(origEnd + padding);
        }
      }
    }

    return segments;
  }

  static List<String> _fields(String s) {
    return s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  }

  static String _trimTrailingPipes(String line) {
    return line.replaceFirst(RegExp(r'\|+$'), '');
  }

  static String _forStart(int millis, int duration) {
    millis -= duration;
    if (millis < 0) {
      millis = 0;
    }
    return millisToTimeRange(millis);
  }

  static String _forEnd(int millis, int duration) {
    millis += duration;
    return millisToTimeRange(millis);
  }

  static int timeRangeToMillis(String timeStr) {
    final parts = timeStr.split(':');
    final secParts = parts[2].split(',');
    final hour = int.parse(parts[0]);
    final min = int.parse(parts[1]);
    final sec = int.parse(secParts[0]);
    final millisec = int.parse(secParts[1]);
    return hour * 3600000 + min * 60000 + sec * 1000 + millisec;
  }

  static String millisToTimeRange(int millis) {
    final hour = millis ~/ 3600000;
    final min = (millis % 3600000) ~/ 60000;
    final sec = (millis % 60000) ~/ 1000;
    final milliSec = millis % 1000;
    return '${_pad(hour, 2)}:${_pad(min, 2)}:${_pad(sec, 2)},${_pad(milliSec, 3)}';
  }

  static String _pad(int n, int width) {
    return n.toString().padLeft(width, '0');
  }
}
