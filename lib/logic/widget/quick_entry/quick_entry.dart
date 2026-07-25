import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
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

  static void openSelect() async {
    var curr = await get(Classroom.curr);
    Select.showSheet(
      title: I18nKey.quickEntry.tr,
      keys: QuickEntryType.values.map((e) => e.title).toList(),
      leadings: QuickEntryType.values.map<Widget?>((e) {
        if (e == curr) {
          return RowWidget.buildGreenDot();
        }
        return const SizedBox(width: 8);
      }).toList(),
      autoHeight: false,
      callback: (index) async {
        await set(Classroom.curr, QuickEntryType.values[index]);
        Snackbar.show(I18nKey.quickEntrySet.tr);
      },
    );
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
