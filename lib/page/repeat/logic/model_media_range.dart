import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'helper.dart';

class MediaRange {
  int start;
  int end;
  bool enable;

  /// 这个区间属于哪个字段（'q'/'a'/'t'）：区间存在该字段块的 'start'/'end' 里，
  /// 该字段的专属媒体（'download'）也在同一块里。
  String fieldAcronym;

  MediaRange({
    required this.start,
    required this.end,
    required this.enable,
    this.fieldAcronym = "q",
  });
}

class MediaRangeHelper {
  Map<int, MediaRange> answerRangeCache = {};
  Map<int, MediaRange> questionRangeCache = {};
  Map<int, MediaRange> tipRangeCache = {};
  final Helper helper;
  static const String defaultStart = "00:00:00,000";
  static const String defaultEnd = "00:00:05,000";
  final SubList<int> reimportBookSub = [];
  final SubList<VerseShow> updateVerseContentSub = [];

  static MediaRange defaultRange() {
    final start = Time.parseTimeToMilliseconds(defaultStart).toInt();
    final end = Time.parseTimeToMilliseconds(defaultEnd).toInt();
    return MediaRange(start: start, end: end, enable: false);
  }

  MediaRangeHelper({
    required this.helper,
  });

  void onInit() {
    reimportBookSub.on([EventTopic.reimportBook], (int? id) {
      answerRangeCache.clear();
      questionRangeCache.clear();
      tipRangeCache.clear();
    });
    updateVerseContentSub.on([EventTopic.updateVerseContent], (VerseShow? v) {
      if (v == null) return;
      answerRangeCache.remove(v.verseId);
      questionRangeCache.remove(v.verseId);
      tipRangeCache.remove(v.verseId);
    });
  }

  void onClose() {
    reimportBookSub.off();
    updateVerseContentSub.off();
  }

  /// 当前 MediaBar 绑定的区间。字段的选取交给 helper.currFieldAcronym()（它已经把步骤、
  /// 悬浮球 Play-* 的临时指定都算进去了），这样视图、播放的文件、区间三者始终指的是同一个字段。
  MediaRange getCurrRange() {
    final curr = helper.currFieldAcronym();
    MediaRange? range = getCurrRangeOf(curr);
    if (range == null || !range.enable) {
      final fallback = curr == QaType.question.acronym ? QaType.answer.acronym : QaType.question.acronym;
      range = getCurrRangeOf(fallback);
    }

    if (range == null || !range.enable) {
      range = defaultRange();
    }
    return range;
  }

  MediaRange? getCurrRangeOf(String acronym) {
    if (acronym == QaType.question.acronym) {
      return getCurrQuestionRange();
    } else if (acronym == QaType.tip.acronym) {
      return getCurrTipRange();
    } else {
      return getCurrAnswerRange();
    }
  }

  MediaRange? getCurrAnswerRange() {
    return _getCurrRange(answerRangeCache, QaType.answer.acronym);
  }

  MediaRange? getCurrQuestionRange() {
    return _getCurrRange(questionRangeCache, QaType.question.acronym);
  }

  MediaRange? getCurrTipRange() {
    return _getCurrRange(tipRangeCache, QaType.tip.acronym);
  }

  MediaRange? _getCurrRange(Map<int, MediaRange> cache, String fieldAcronym) {
    if (helper.logic.currVerse == null) {
      return null;
    }
    MediaRange? ret = cache[helper.logic.currVerse!.verseId];
    if (ret != null) {
      return ret;
    }
    final s = helper.getCurrVerseMap();
    if (s == null) {
      return null;
    }
    String? startStr = VerseField.getStr(s, fieldAcronym, VerseField.start);
    String? endStr = VerseField.getStr(s, fieldAcronym, VerseField.end);
    bool enable = true;
    if (startStr == null) {
      startStr = defaultStart;
      enable = false;
    }
    if (endStr == null) {
      endStr = defaultEnd;
      enable = false;
    }
    final start = Time.parseTimeToMilliseconds(startStr).toInt();
    final end = Time.parseTimeToMilliseconds(endStr).toInt();
    ret = MediaRange(start: start, end: end, enable: enable, fieldAcronym: fieldAcronym);
    cache[helper.logic.currVerse!.verseId] = ret;
    return ret;
  }

  MediaEditCallback? mediaRangeEdit(MediaRange range) {
    if (helper.showMode.value != ShowMode.edit) {
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
          if (VerseField.getStr(map, range.fieldAcronym, VerseField.start) == null) {
            VerseField.setStr(map, range.fieldAcronym, VerseField.start, defaultStart);
          }
          if (VerseField.getStr(map, range.fieldAcronym, VerseField.end) == null) {
            VerseField.setStr(map, range.fieldAcronym, VerseField.end, defaultEnd);
          }
          VerseField.setStr(map, range.fieldAcronym, start ? VerseField.start : VerseField.end, str);
          String jsonStr = jsonEncode(map);
          var verseId = helper.getCurrVerse()!.verseId;
          await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
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
          action: MsgBox.buttonsWithDivider(
            buttons: [
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
            ],
          ),
        );
      } else {
        Snackbar.show(I18nKey.labelDataNotChange.tr);
      }
    };
  }

  static VerseShow? improveLastCopyContent(VerseShow v) {
    final c = ChapterHelp.getCache(v.chapterId);
    final b = BookHelp.getCache(v.bookId);
    if (c == null) {
      return null;
    }
    if (b == null) {
      return null;
    }
    var vm = jsonDecode(v.verseContent);
    String? viewName = ListUtil.getValue<String>([
      vm,
      jsonDecode(c.chapterContent),
      jsonDecode(b.bookContent),
    ], 's');

    if (viewName == null) {
      return null;
    }
    RepeatViewEnum? view = RepeatViewEnum.values.firstWhereOrNull((e) => e.name == viewName);
    switch (view) {
      case RepeatViewEnum.audio:
      case RepeatViewEnum.video:
        // 字段块是嵌套的 map，浅拷贝会跟原内容共用同一个块，必须每块单独复制一份再改。
        final Map<String, dynamic> m = Map<String, dynamic>.from(vm);
        for (var acronym in [QaType.answer.acronym, QaType.question.acronym]) {
          final field = VerseField.of(m, acronym);
          if (field == null) {
            continue;
          }
          m[acronym] = Map<String, dynamic>.from(field);
          final endStr = VerseField.getStr(m, acronym, VerseField.end);
          if (endStr == null) {
            continue;
          }
          final int endMs = Time.parseTimeToMilliseconds(endStr).toInt();
          final int startMs = endMs - 500;
          VerseField.setStr(m, acronym, VerseField.start, Time.convertMsToString(startMs));
          VerseField.setStr(m, acronym, VerseField.end, Time.convertMsToString(startMs + 6000));
        }
        var newVerseShow = v.copy();
        newVerseShow.verseContent = jsonEncode(m);
        return newVerseShow;
      default:
        return null;
    }
  }
}
