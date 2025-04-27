import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'helper.dart';

class MediaRange {
  int start;
  int end;
  bool enable;
  String jsonStartName;
  String jsonEndName;

  MediaRange({
    required this.start,
    required this.end,
    required this.enable,
    this.jsonStartName = "",
    this.jsonEndName = "",
  });
}

class MediaRangeHelper {
  Map<int, MediaRange> answerRangeCache = {};
  Map<int, MediaRange> questionRangeCache = {};
  final Helper helper;

  MediaRangeHelper({
    required this.helper,
  }) {
    ScheduleDao.setSegmentShowContent.add((int id) {
      answerRangeCache.remove(id);
      questionRangeCache.remove(id);
    });
  }

  MediaRange? getCurrAnswerRange() {
    if (helper.logic.currSegment == null) {
      return null;
    }
    MediaRange? ret = answerRangeCache[helper.logic.currSegment!.segmentKeyId];
    if (ret != null) {
      return ret;
    }
    final s = helper.getCurrSegmentMap();
    if (s == null) {
      return null;
    }
    String jsonStartName = "aStart";
    String jsonEndName = "aEnd";
    String? startStr = s[jsonStartName] as String?;
    String? endStr = s[jsonEndName] as String?;
    if (startStr != null && //
        endStr != null &&
        startStr.isNotEmpty &&
        endStr.isNotEmpty) {
      final start = Time.parseTimeToMilliseconds(startStr).toInt();
      final end = Time.parseTimeToMilliseconds(endStr).toInt();
      ret = MediaRange(start: start, end: end, enable: true);
      answerRangeCache[helper.logic.currSegment!.segmentKeyId] = ret;
    } else {
      ret = MediaRange(start: 0, end: 0, enable: false);
      answerRangeCache[helper.logic.currSegment!.segmentKeyId] = ret;
    }
    ret.jsonStartName = jsonStartName;
    ret.jsonEndName = jsonEndName;
    return ret;
  }

  MediaRange? getCurrQuestionRange() {
    if (helper.logic.currSegment == null) {
      return null;
    }
    MediaRange? ret = questionRangeCache[helper.logic.currSegment!.segmentKeyId];
    if (ret != null) {
      return ret;
    }
    final s = helper.getCurrSegmentMap();
    if (s == null) {
      return null;
    }
    String jsonStartName = "qStart";
    String jsonEndName = "qEnd";
    String? startStr = s[jsonStartName] as String?;
    String? endStr = s[jsonEndName] as String?;
    if (startStr != null && //
        endStr != null &&
        startStr.isNotEmpty &&
        endStr.isNotEmpty) {
      final start = Time.parseTimeToMilliseconds(startStr).toInt();
      final end = Time.parseTimeToMilliseconds(endStr).toInt();
      ret = MediaRange(start: start, end: end, enable: true);
      questionRangeCache[helper.logic.currSegment!.segmentKeyId] = ret;
    } else {
      ret = MediaRange(start: 0, end: 0, enable: false);
      questionRangeCache[helper.logic.currSegment!.segmentKeyId] = ret;
    }
    ret.jsonStartName = jsonStartName;
    ret.jsonEndName = jsonEndName;
    return ret;
  }

  MediaEditCallback? mediaRangeEdit(MediaRange range) {
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
          title: I18nKey.labelTips.tr,
          desc: start ? I18nKey.labelSaveToStart.trArgs([str]) : I18nKey.labelSaveToEnd.tr.trArgs([str]),
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
