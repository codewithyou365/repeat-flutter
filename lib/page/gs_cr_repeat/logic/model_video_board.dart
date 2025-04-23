import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/lesson_key_dao.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'helper.dart';

class VideoBoard {
  final double x;
  final double y;
  final double w;
  final double h;

  const VideoBoard({
    this.x = 0.0,
    this.y = 0.8,
    this.w = 1.0,
    this.h = 0.2,
  });

  factory VideoBoard.fromJson(Map<String, dynamic> json) {
    return VideoBoard(
      x: (json['x'] as num? ?? 0.0).toDouble(),
      y: (json['y'] as num? ?? 0.8).toDouble(),
      w: (json['w'] as num? ?? 1.0).toDouble(),
      h: (json['h'] as num? ?? 0.2).toDouble(),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'w': w,
      'h': h,
    };
  }

  // 复制并修改属性
  VideoBoard copyWith({
    double? x,
    double? y,
    double? w,
    double? h,
  }) {
    return VideoBoard(
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
    );
  }
}

class MediaSegmentHelper {
  Map<int, List<VideoBoard>> lessonVideoBoardCache = {};
  Map<int, List<VideoBoard>> segmentVideoBoardCache = {};
  final Helper helper;
  static const String jsonName = "videoBoard";

  MediaSegmentHelper({
    required this.helper,
  }) {
    ScheduleDao.setSegmentShowContent.add((int id) {
      segmentVideoBoardCache.remove(id);
    });
    LessonKeyDao.setLessonShowContent.add((int id) {
      lessonVideoBoardCache.remove(id);
    });
  }

  List<VideoBoard>? getCurrLessonVideoBoard() {
    if (helper.logic.currSegment == null) {
      return null;
    }

    final lessonKeyId = helper.logic.currSegment!.lessonKeyId;
    List<VideoBoard>? ret = lessonVideoBoardCache[lessonKeyId];
    if (ret != null) {
      return ret;
    }

    final lessonMap = helper.getCurrLessonMap();
    if (lessonMap == null) {
      return null;
    }

    final List<dynamic>? list = lessonMap[jsonName] as List<dynamic>?;
    if (list != null) {
      ret = list.map((e) => VideoBoard.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      ret = [];
    }

    lessonVideoBoardCache[lessonKeyId] = ret;
    return ret;
  }

  List<VideoBoard>? getCurrQuestionRange() {
    if (helper.logic.currSegment == null) {
      return null;
    }

    final segmentKeyId = helper.logic.currSegment!.segmentKeyId;
    List<VideoBoard>? ret = segmentVideoBoardCache[segmentKeyId];
    if (ret != null) {
      return ret;
    }

    final segmentMap = helper.getCurrSegmentMap();
    if (segmentMap == null) {
      return null;
    }

    final List<dynamic>? list = segmentMap[jsonName] as List<dynamic>?;
    if (list != null) {
      ret = list.map((e) => VideoBoard.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      ret = [];
    }

    segmentVideoBoardCache[segmentKeyId] = ret;
    return ret;
  }
}
