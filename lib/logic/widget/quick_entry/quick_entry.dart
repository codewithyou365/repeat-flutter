import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_support.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// The quick entry configured in the classroom page. When the user taps a
/// classroom in ScPage, the app walks the same path the user would tap by hand
/// until it reaches the target screen.
enum QuickEntryType {
  none,
  // content only
  globalBrowse,
  examine,
  browse,
  // content + open the game panel automatically
  globalBrowseGame,
  examineGame,
  browseGame,
  // 息屏录音建章。没有游戏变体，进哪本书由 [RecordBookPick] 决定。
  recordTranslate,
}

/// 快速进入选了 [QuickEntryType.recordTranslate] 时，进哪本书。
/// 课堂里只有一本书时这个设置不起作用——直接进那本，不问。
enum RecordBookPick {
  first,
  last,
  ask,
}

extension RecordBookPickExt on RecordBookPick {
  String get title {
    switch (this) {
      case RecordBookPick.first:
        return I18nKey.quickEntryRecordBookFirst.tr;
      case RecordBookPick.last:
        return I18nKey.quickEntryRecordBookLast.tr;
      case RecordBookPick.ask:
        return I18nKey.quickEntryRecordBookAsk.tr;
    }
  }
}

extension QuickEntryTypeExt on QuickEntryType {
  bool get withGame => this == QuickEntryType.globalBrowseGame || this == QuickEntryType.examineGame || this == QuickEntryType.browseGame;

  /// The content type without the game modifier.
  QuickEntryType get content {
    switch (this) {
      case QuickEntryType.globalBrowseGame:
        return QuickEntryType.globalBrowse;
      case QuickEntryType.examineGame:
        return QuickEntryType.examine;
      case QuickEntryType.browseGame:
        return QuickEntryType.browse;
      default:
        return this;
    }
  }

  String get title {
    switch (this) {
      case QuickEntryType.globalBrowse:
        return I18nKey.quickEntryGlobalBrowse.tr;
      case QuickEntryType.examine:
        return I18nKey.quickEntryExamine.tr;
      case QuickEntryType.browse:
        return I18nKey.quickEntryBrowse.tr;
      case QuickEntryType.globalBrowseGame:
        return I18nKey.quickEntryGlobalBrowseGame.tr;
      case QuickEntryType.examineGame:
        return I18nKey.quickEntryExamineGame.tr;
      case QuickEntryType.browseGame:
        return I18nKey.quickEntryBrowseGame.tr;
      case QuickEntryType.recordTranslate:
        return I18nKey.quickEntryRecordTranslate.tr;
      default:
        return I18nKey.quickEntryNone.tr;
    }
  }
}

class QuickEntry {
  /// Set by ScLogic when a classroom is tapped, consumed by ScCrLogic.
  static QuickEntryType? pending;

  /// Set by ScCrLogic, consumed by RepeatLogic once the repeat page is ready.
  static bool autoOpenGame = false;

  static OverlayEntry? _guiding;
  static Timer? _guidingTimer;

  static Future<QuickEntryType> get(int classroomId) async {
    var value = await Db().db.crKvDao.getStr(classroomId, CrK.quickEntry);
    if (value == null || value.isEmpty) {
      return QuickEntryType.none;
    }
    return QuickEntryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuickEntryType.none,
    );
  }

  static Future<void> set(int classroomId, QuickEntryType type) async {
    await Db().db.crKvDao.insertOrReplace(CrKv(classroomId, CrK.quickEntry, type.name));
  }

  /// 默认 [RecordBookPick.last]：最后建的那本通常就是眼下在录的那本。
  static Future<RecordBookPick> getBookPick(int classroomId) async {
    var value = await Db().db.crKvDao.getStr(classroomId, CrK.aiRecordBookPick);
    if (value == null || value.isEmpty) {
      return RecordBookPick.last;
    }
    return RecordBookPick.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecordBookPick.last,
    );
  }

  static Future<void> setBookPick(int classroomId, RecordBookPick pick) async {
    await Db().db.crKvDao.insertOrReplace(CrKv(classroomId, CrK.aiRecordBookPick, pick.name));
  }

  /// 选择表里能出现的项。平台跑不了端上模型时（web/桌面）录音那条路从 UI 上
  /// 根本到不了，就别摆出来——和 ScCrMaterialLogic.addChapter 一个道理。
  static List<QuickEntryType> selectableTypes() {
    if (AiSupport.available) {
      return QuickEntryType.values;
    }
    return QuickEntryType.values.where((e) => e != QuickEntryType.recordTranslate).toList();
  }

  static void openSelect() async {
    var curr = await get(Classroom.curr);
    // 过滤过了，回调不能再拿 QuickEntryType.values[index] 反查
    var types = selectableTypes();
    var index = await Select.showSheet(
      title: I18nKey.quickEntry.tr,
      keys: types.map((e) => e.title).toList(),
      leadings: types.map<Widget?>((e) {
        if (e == curr) {
          return RowWidget.buildGreenDot();
        }
        return const SizedBox(width: 8);
      }).toList(),
      autoHeight: false,
    );
    if (index == null) {
      return;
    }
    var type = types[index];
    await set(Classroom.curr, type);
    if (type == QuickEntryType.recordTranslate) {
      // 必须等第一个表关干净再弹第二个：Select 的 onTap 是先跑 callback 再
      // Get.back()，在 callback 里弹等于插在关闭动画中间。
      await selectRecordBook();
    }
    Snackbar.show(I18nKey.quickEntrySet.tr);
  }

  /// 第二个表：录音翻译进哪本书。划走不改，快速进入本身已经存好了。
  static Future<void> selectRecordBook() async {
    var curr = await getBookPick(Classroom.curr);
    var index = await Select.showSheet(
      title: I18nKey.quickEntryRecordBook.tr,
      keys: RecordBookPick.values.map((e) => e.title).toList(),
      leadings: RecordBookPick.values.map<Widget?>((e) {
        if (e == curr) {
          return RowWidget.buildGreenDot();
        }
        return const SizedBox(width: 8);
      }).toList(),
    );
    if (index == null) {
      return;
    }
    await setBookPick(Classroom.curr, RecordBookPick.values[index]);
  }

  /// A translucent hint that never blocks the user's operation.
  static void showGuiding() {
    if (_guiding != null) {
      return;
    }
    // the root navigator's overlay, so the hint survives route push/pop
    var overlay = Get.key.currentState?.overlay;
    if (overlay == null) {
      var context = Get.context;
      if (context == null) {
        return;
      }
      overlay = Overlay.of(context, rootOverlay: true);
    }
    var entry = OverlayEntry(
      builder: (BuildContext context) => IgnorePointer(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 80.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20.w),
              ),
              child: Text(
                I18nKey.guiding.tr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16.sp,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _guiding = entry;
    overlay.insert(entry);
    // in case the guiding chain is broken by an unexpected error
    _guidingTimer?.cancel();
    _guidingTimer = Timer(const Duration(seconds: 20), hideGuiding);
  }

  static void hideGuiding() {
    _guidingTimer?.cancel();
    _guidingTimer = null;
    _guiding?.remove();
    _guiding = null;
  }
}
