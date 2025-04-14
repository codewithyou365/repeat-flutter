import 'dart:convert';

import 'package:repeat_flutter/logic/base/constant.dart' show DocPath;
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class DocHelp {
  static void walkLessonMedia({
    required Map<String, dynamic> map,
    required Function(String filename) walker,
  }) {
    List<Map<String, dynamic>> lessons = map["lesson"] as List<Map<String, dynamic>>;
    for (int lessonIndex = 0; lessonIndex < lessons.length; lessonIndex++) {
      var lesson = lessons[lessonIndex];
      String? url = lesson["url"];
      if (url != null) {
        var extension = url.split('.').last;
        walker(DocPath.getMediaFileName(lessonIndex, extension));
      }
    }
  }

  static Future<bool> getDocMapFromDb({
    required int contentId,
    required Map<String, dynamic> ret,
    String? rootUrl,
    bool shareNote = false,
  }) async {
    await SegmentHelp.tryGen(force: true);
    await LessonHelp.tryGen(force: true);

    var segmentCache = SegmentHelp.cache;
    var lessonCache = LessonHelp.cache;

    Map<int, List<SegmentShow>> lessonToSegmentShow = {};

    for (var segment in segmentCache) {
      if (segment.contentId == contentId) {
        int lessonKey = segment.lessonIndex;

        if (!lessonToSegmentShow.containsKey(lessonKey)) {
          lessonToSegmentShow[lessonKey] = [];
        }

        lessonToSegmentShow[lessonKey]!.add(segment);
      }
    }

    lessonToSegmentShow.forEach((lessonIndex, segments) {
      segments.sort((a, b) => a.segmentIndex.compareTo(b.segmentIndex));
    });

    List<Map<String, dynamic>> lessonsList = [];
    for (int i = 0; i < lessonCache.length; i++) {
      var lesson = lessonCache[i];
      if (lesson.contentId == contentId) {
        Map<String, dynamic> lessonData = {};

        try {
          lessonData = jsonDecode(lesson.lessonContent);
        } catch (e) {
          Snackbar.show("Error parsing lesson content: $e");
          return false;
        }

        List<SegmentShow> segmentsForLesson = lessonToSegmentShow[lesson.lessonIndex] ?? [];
        List<Map<String, dynamic>> segmentsList = [];
        for (var segment in segmentsForLesson) {
          Map<String, dynamic> segmentData = {};

          try {
            segmentData = jsonDecode(segment.segmentContent);
          } catch (e) {
            Snackbar.show("Error parsing segment content: $e");
            return false;
          }

          if (shareNote && segment.segmentNote.isNotEmpty) {
            segmentData["n"] = segment.segmentNote;
          }

          segmentsList.add(segmentData);
        }
        if (rootUrl != null) {
          String url = lessonData['url'];
          if (lessonData['mediaExtension'] == null || lessonData['mediaExtension'] == '') {
            lessonData['mediaExtension'] = url.split('.').last;
          }
          lessonData["url"] = '';
        }
        lessonData["segment"] = segmentsList;
        lessonsList.add(lessonData);
      }
    }

    ret["lesson"] = lessonsList;

    return true;
  }
}
