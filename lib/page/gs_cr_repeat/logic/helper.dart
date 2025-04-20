import 'dart:convert';

import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/segment_help.dart';

import 'constant.dart';
import 'repeat_logic.dart';

class Helper {
  late RepeatLogic logic;
  late List<Content> contents;
  late String rootPath;
  double topBarHeight;
  bool landscape;
  bool? customFullScreen;

  Map<int, RepeatDoc> docCache = {};
  Map<int, Map<String, dynamic>> docMapCache = {};
  Map<int, Map<String, dynamic>> segmentMapCache = {};
  Map<int, List<String>> pathCache = {};

  Helper({
    this.landscape = false,
    this.topBarHeight = 50,
  });

  Future<void> init(RepeatLogic logic) async {
    this.logic = logic;
    contents = await Db().db.contentDao.getAllContent(Classroom.curr);
    rootPath = await DocPath.getContentPath();
  }

  void update() {
    logic.update();
  }

  bool get fullScreen {
    if (customFullScreen != null) {
      return customFullScreen!;
    }
    return landscape;
  }

  RepeatStep get step {
    return logic.step;
  }

  String? getCurrSegmentContent() {
    if (logic.currSegment == null) {
      return null;
    }
    var segment = SegmentHelp.getCache(logic.currSegment!.segmentKeyId);
    if (segment == null) {
      return null;
    }
    return segment.segmentContent;
  }

  String? getCurrLessonContent() {
    if (logic.currSegment == null) {
      return null;
    }
    var lesson = LessonHelp.getCache(logic.currSegment!.lessonKeyId);
    if (lesson == null) {
      return null;
    }
    return lesson.lessonContent;
  }

  String? getCurrRootContent() {
    if (logic.currSegment == null) {
      return null;
    }
    Content ret = contents.firstWhere((c) => c.serial == logic.currSegment!.contentSerial, orElse: () => Content.empty());
    if (ret.id == null) {
      return null;
    }
    return ret.content;
  }

  Map<String, dynamic>? getCurrSegmentMap() {
    if (logic.currSegment == null) {
      return null;
    }
    Map<String, dynamic>? ret = segmentMapCache[logic.currSegment!.segmentKeyId];
    String? segmentContent = getCurrSegmentContent();
    if (segmentContent == null) {
      return null;
    }
    ret = jsonDecode(segmentContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    segmentMapCache[logic.currSegment!.segmentKeyId] = ret;
    return ret;
  }

  Map<String, dynamic>? getCurrRepeatDocMap() {
    if (logic.currSegment == null) {
      return null;
    }
    Map<String, dynamic>? ret = docMapCache[logic.currSegment!.segmentKeyId];
    if (ret != null) {
      return ret;
    }
    String? rootContent = getCurrRootContent();
    if (rootContent == null) {
      return null;
    }
    String? lessonContent = getCurrLessonContent();
    if (lessonContent == null) {
      return null;
    }

    var segmentJsonMap = getCurrSegmentMap();
    var rootJsonMap = jsonDecode(rootContent);
    var lessonJsonMap = jsonDecode(lessonContent);
    lessonJsonMap['s'] = [segmentJsonMap];
    rootJsonMap['l'] = [lessonJsonMap];
    docMapCache[logic.currSegment!.segmentKeyId] = rootJsonMap;
    return rootJsonMap;
  }

  RepeatDoc? getCurrRepeatDoc() {
    if (logic.currSegment == null) {
      return null;
    }
    RepeatDoc? ret = docCache[logic.currSegment!.segmentKeyId];
    final map = getCurrRepeatDocMap();
    if (map == null) {
      return null;
    }
    ret = RepeatDoc.fromJson(map);
    docCache[logic.currSegment!.segmentKeyId] = ret;
    return ret;
  }

  List<String>? getPaths() {
    if (logic.currSegment == null) {
      return null;
    }
    List<String>? ret = pathCache[logic.currSegment!.segmentKeyId];
    if (ret != null) {
      return ret;
    }
    var doc = getCurrRepeatDoc();
    if (doc == null) {
      return null;
    }
    List<Download> downloads = DocHelp.getDownloads(doc, rootUrl: "");
    ret = [];
    for (var download in downloads) {
      ret.add(rootPath.joinPath(DocPath.getRelativePath(logic.currSegment!.contentSerial)).joinPath(download.path));
    }
    pathCache[logic.currSegment!.segmentKeyId] = ret;
    return ret;
  }
}
