import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/dao/lesson_key_dao.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'repeat_logic.dart';

class Helper {
  bool initialized = false;
  late RepeatLogic logic;
  late List<Content> contents;
  late String rootPath;

  late double screenWidth;
  late double screenHeight;
  bool landscape = false;
  late double leftPadding;
  late double topPadding;
  double topBarHeight = 50;
  late Widget Function() topBar;
  double bottomBarHeight = 50;
  late Widget Function({required double width}) bottomBar;
  late Widget? Function(QaType type) text;

  bool edit = false;
  Map<int, Map<String, dynamic>> rootMapCache = {};

  Map<int, Map<String, dynamic>> lessonMapCache = {};
  Map<int, List<String>> lessonPathCache = {};

  Map<int, Map<String, dynamic>> segmentMapCache = {};

  Helper() {
    LessonKeyDao.setLessonShowContent = [];
    LessonKeyDao.setLessonShowContent.add((int id) {
      lessonMapCache.remove(id);
      lessonPathCache.remove(id);
    });

    ScheduleDao.setSegmentShowContent = [];
    ScheduleDao.setSegmentShowContent.add((int id) {
      segmentMapCache.remove(id);
    });
  }

  Future<void> init(RepeatLogic logic) async {
    initialized = true;
    this.logic = logic;
    contents = await Db().db.contentDao.getAllContent(Classroom.curr);
    rootPath = await DocPath.getContentPath();
  }

  void update() {
    logic.update();
  }

  RepeatStep get step {
    return logic.step;
  }

  TipLevel get tip {
    return logic.tip;
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

  Map<String, dynamic>? getCurrRootMap() {
    if (logic.currSegment == null) {
      return null;
    }
    Map<String, dynamic>? ret = rootMapCache[logic.currSegment!.contentSerial];
    String? rootContent = getCurrRootContent();
    if (rootContent == null) {
      return null;
    }
    ret = jsonDecode(rootContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    rootMapCache[logic.currSegment!.contentSerial] = ret;
    return ret;
  }

  Map<String, dynamic>? getCurrLessonMap() {
    if (logic.currSegment == null) {
      return null;
    }
    Map<String, dynamic>? ret = lessonMapCache[logic.currSegment!.lessonKeyId];
    String? lessonContent = getCurrLessonContent();
    if (lessonContent == null) {
      return null;
    }
    ret = jsonDecode(lessonContent);
    if (ret is! Map<String, dynamic>) {
      return null;
    }
    lessonMapCache[logic.currSegment!.lessonKeyId] = ret;
    return ret;
  }

  SegmentTodayPrg? getCurrSegment() {
    return logic.currSegment;
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
    return rootJsonMap;
  }

  RepeatDoc? getCurrRepeatDoc() {
    if (logic.currSegment == null) {
      return null;
    }
    final map = getCurrRepeatDocMap();
    if (map == null) {
      return null;
    }
    return RepeatDoc.fromJson(map);
  }

  List<String>? getLessonPaths() {
    if (logic.currSegment == null) {
      return null;
    }
    List<String>? ret = lessonPathCache[logic.currSegment!.lessonKeyId];
    if (ret != null) {
      return ret;
    }
    var doc = getCurrLessonMap();
    if (doc == null) {
      return null;
    }
    Lesson lesson = Lesson.fromJson(doc);
    var downloads = lesson.download ?? [];
    ret = [];
    for (var download in downloads) {
      ret.add(rootPath.joinPath(DocPath.getRelativePath(logic.currSegment!.contentSerial)).joinPath(download.path));
    }
    lessonPathCache[logic.currSegment!.lessonKeyId] = ret;
    return ret;
  }

  String? getCurrViewName() {
    String? ret;
    var m = getCurrSegmentMap();
    if (m != null && m['v'] != null) {
      ret = m['v'] as String;
    }
    if (ret == null) {
      m = getCurrLessonMap();
      if (m != null && m['v'] != null) {
        ret = m['v'] as String;
      }
    }
    if (ret == null) {
      m = getCurrRootMap();
      if (m != null && m['v'] != null) {
        ret = m['v'] as String;
      }
    }
    if (ret != null) {
      return ret.toLowerCase();
    }
    return null;
  }

  Future<bool> tryImportMedia({
    required String localMediaPath,
    required List<String> allowedExtensions,
  }) async {
    var file = File(localMediaPath);
    var exist = await file.exists();
    if (exist) {
      return true;
    } else {
      MsgBox.yesOrNo(
        title: I18nKey.labelTips.tr,
        desc: I18nKey.labelFileNotFound.tr,
        no: () async {
          Get.back();
          Get.back();
        },
        yes: () async {
          FilePickerResult? result;
          if (allowedExtensions.length == 1 && allowedExtensions.first == 'mp4') {
            result = await FilePicker.platform.pickFiles(
              type: FileType.video,
            );
          } else {
            result = await FilePicker.platform.pickFiles(
              type: FileType.media,
            );
          }

          String pickedPath = "";
          String pickedName = "";
          if (result != null && result.files.single.path != null) {
            pickedPath = result.files.single.path!;
            pickedName = result.files.single.name;
          } else {
            Snackbar.show(I18nKey.labelLocalImportCancel.tr);
            return;
          }

          try {
            var s = getCurrSegment()!;
            String hash = await Hash.toSha1(pickedPath);
            Download download = Download(url: pickedName, hash: hash);
            var rootPath = await DocPath.getContentPath();
            String localFolder = rootPath.joinPath(DocPath.getRelativePath(s.contentSerial).joinPath(download.folder));
            if (!allowedExtensions.containsIgnoreCase(download.extension)) {
              Snackbar.show(I18nKey.labelFileExtensionNotMatch.trArgs([jsonEncode(allowedExtensions)]));
              return;
            }

            await Folder.ensureExists(localFolder);
            await File(pickedPath).copy(localFolder.joinPath(download.name));
            var lessonKeyId = s.lessonKeyId;
            var m = getCurrLessonMap()!;
            m['d'] = [download];
            Db().db.lessonKeyDao.updateLessonContent(lessonKeyId, jsonEncode(m));
            Get.back();
            Get.back();
          } catch (e) {
            Snackbar.show(e.toString());
            return;
          }
        },
      );
      return false;
    }
  }
}
