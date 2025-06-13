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
  static const String defaultStart = "00:00:00,000";
  static const String defaultEnd = "00:00:05,000";

  MediaRangeHelper({
    required this.helper,
  }) {
    ScheduleDao.setVerseShowContent.add((int id) {
      answerRangeCache.remove(id);
      questionRangeCache.remove(id);
    });
  }

  MediaRange? getCurrAnswerRange() {
    return _getCurrRange(answerRangeCache, "aStart", "aEnd");
  }

  MediaRange? getCurrQuestionRange() {
    return _getCurrRange(questionRangeCache, "qStart", "qEnd");
  }

  MediaRange? _getCurrRange(Map<int, MediaRange> cache, String jsonStartName, String jsonEndName) {
    if (helper.logic.currVerse == null) {
      return null;
    }
    MediaRange? ret = cache[helper.logic.currVerse!.verseKeyId];
    if (ret != null) {
      return ret;
    }
    final s = helper.getCurrVerseMap();
    if (s == null) {
      return null;
    }
    String? startStr = s[jsonStartName] as String?;
    String? endStr = s[jsonEndName] as String?;
    bool enable = true;
    if (startStr == null || startStr.isEmpty) {
      startStr = defaultStart;
      enable = false;
    }
    if (endStr == null || endStr.isEmpty) {
      endStr = defaultEnd;
      enable = false;
    }
    final start = Time.parseTimeToMilliseconds(startStr).toInt();
    final end = Time.parseTimeToMilliseconds(endStr).toInt();
    ret = MediaRange(start: start, end: end, enable: enable);
    cache[helper.logic.currVerse!.verseKeyId] = ret;
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
          Map<String, dynamic>? map = helper.getCurrVerseMap();
          if (map == null) {
            Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["map"]));
            return;
          }
          if (map[range.jsonStartName] == null) {
            map[range.jsonStartName] = defaultStart;
          }
          if (map[range.jsonEndName] == null) {
            map[range.jsonEndName] = defaultEnd;
          }
          String jsonName = start ? range.jsonStartName : range.jsonEndName;
          map[jsonName] = str;
          String jsonStr = jsonEncode(map);
          var verseKeyId = helper.getCurrVerse()!.verseKeyId;
          await Db().db.scheduleDao.tUpdateVerseContent(verseKeyId, jsonStr);
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
