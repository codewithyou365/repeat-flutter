import 'dart:convert';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/logic/base/constant.dart' show DocPath;
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class DocHelp {
  static Future<String?> toJsonString(String path) async {
    var rootPath = await DocPath.getContentPath();
    File file = File(rootPath.joinPath(path));
    bool exist = await file.exists();
    if (!exist) {
      return null;
    }
    return await file.readAsString();
  }

  static Future<Map<String, dynamic>?> toJsonMap(String path) async {
    String? jsonString = await toJsonString(path);
    if (jsonString == null) {
      return null;
    }
    Map<String, dynamic> jsonData = convert.jsonDecode(jsonString);
    return jsonData;
  }

  static Future<RepeatDoc?> fromPath(String path) async {
    Map<String, dynamic>? jsonData = await toJsonMap(path);
    if (jsonData != null) {
      return RepeatDoc.fromJson(jsonData);
    }
    return null;
  }

  static List<Download> getDownloads(RepeatDoc kv) {
    List<Download> ret = [];
    Map<String, Download> hashToDownloads = {};
    void tryAppendDownload(Download d, String? rootUrl) {
      if (hashToDownloads[d.hash] == null) {
        Download? curr;
        if (d.url.startsWith("http")) {
          curr = d;
        } else if (rootUrl != null) {
          curr = Download(url: rootUrl.joinPath(d.url), hash: d.hash);
        }
        if (curr != null) {
          ret.add(curr);
          hashToDownloads[curr.hash] = curr;
        }
      }
    }

    if (kv.download != null) {
      for (var d in kv.download!) {
        tryAppendDownload(d, kv.rootUrl);
      }
    }
    for (var lesson in kv.lesson) {
      if (lesson.download != null) {
        for (var d in lesson.download!) {
          tryAppendDownload(d, lesson.rootUrl ?? kv.rootUrl);
        }
      }
      for (var segment in lesson.segment) {
        if (segment.download != null) {
          for (var d in segment.download!) {
            tryAppendDownload(d, segment.rootUrl ?? lesson.rootUrl ?? kv.rootUrl);
          }
        }
      }
    }
    return ret;
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
          lessonData["u"] = '';
        }
        lessonData["s"] = segmentsList;
        lessonsList.add(lessonData);
      }
    }

    ret["l"] = lessonsList;

    return true;
  }
}
