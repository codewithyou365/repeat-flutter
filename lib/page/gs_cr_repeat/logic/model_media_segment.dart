import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'helper.dart';

class Range {
  int start;
  int end;
  bool enable;
  String jsonStartName;
  String jsonEndName;

  Range({
    required this.start,
    required this.end,
    required this.enable,
    this.jsonStartName = "",
    this.jsonEndName = "",
  });
}

class MediaSegmentHelper {
  Map<int, MediaSegment> mediaSegmentCache = {};
  Map<int, Range> answerRangeCache = {};
  Map<int, Range> questionRangeCache = {};
  final Helper helper;

  MediaSegmentHelper({
    required this.helper,
  }) {
    ScheduleDao.setSegmentShowContent.add((int id) {
      mediaSegmentCache.remove(id);
      answerRangeCache.remove(id);
      questionRangeCache.remove(id);
    });
  }

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
    ret.jsonStartName = "aStart";
    ret.jsonEndName = "aEnd";
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
    ret.jsonStartName = "qStart";
    ret.jsonEndName = "qEnd";
    return ret;
  }

  MediaEditCallback? mediaEdit(Range range) {
    if (!helper.edit) {
      return null;
    }
    return (int currMs) async {
      var str = Time.convertMsToString(currMs);
      save({required bool start}) {
        showTransparentOverlay(() async {
          Map<String, dynamic>? map = helper.getCurrSegmentMap();
          if (map == null) {
            Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["map"]));
            return;
          }
          String jsonName = start ? range.jsonStartName : range.jsonEndName;
          map[jsonName] = str;
          String jsonStr = jsonEncode(map);
          var segmentKeyId = helper.getCurrSegment()!.segmentKeyId;
          await Db().db.scheduleDao.tUpdateSegmentContent(segmentKeyId, jsonStr);
          helper.logic.update();
          Get.back();
          Snackbar.show(I18nKey.labelSaved.tr);
        });
      }

      saveWithConfirm({required bool start}) {
        MsgBox.yesOrNo(
          I18nKey.labelTips.tr,
          start ? I18nKey.labelSaveToStart.trArgs([str]) : I18nKey.labelSaveToEnd.tr.trArgs([str]),
          yes: () => save(start: start),
        );
      }

      if (currMs < range.start - 50) {
        saveWithConfirm(start: true);
      } else if (currMs > range.end + 50) {
        saveWithConfirm(start: false);
      } else if (range.start + 50 < currMs && currMs < range.end - 50) {
        MsgBox.myDialog(
          title: I18nKey.labelTips.tr,
          content: MsgBox.content(I18nKey.labelStartOrEnd.trArgs([str])),
          action: MsgBox.buttonsWithDivider(buttons: [
            MsgBox.button(
              text: I18nKey.btnCancel.tr,
              onPressed: () {
                Get.back();
              },
            ),
            MsgBox.button(
              text: I18nKey.btnStart.tr,
              onPressed: () {
                save(start: true);
              },
            ),
            MsgBox.button(
              text: I18nKey.btnEnd.tr,
              onPressed: () {
                save(start: false);
              },
            ),
          ]),
        );
      } else {
        Snackbar.show(I18nKey.labelDataNotChange.tr);
      }
    };
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
