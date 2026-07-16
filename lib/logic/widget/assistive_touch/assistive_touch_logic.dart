import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/assistive_touch_action.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_logic.dart';
import 'package:repeat_flutter/page/repeat/logic/repeat_flow_for_browse.dart';
import 'package:repeat_flutter/page/repeat/logic/repeat_flow_for_examine.dart';
import 'package:repeat_flutter/page/repeat/repeat_logic.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 内置动作（不是用户自己配的 AssistiveTouchAction 预设）。跟自定义动作一样，可以在自定义菜单里
/// 长按移除、点"新增"时重新加回来。TTS-*/Play-* 几个目前只是占位，点了不会有任何反应。
enum BuiltInAction {
  playQ,
  playA,
  playTips,
  deleteVerse,
  ttsQ,
  ttsA,
  ttsTips,
  ttsNote,
}

extension BuiltInActionX on BuiltInAction {
  IconData get icon {
    switch (this) {
      case BuiltInAction.deleteVerse:
        return Icons.delete_outline;
      case BuiltInAction.ttsNote:
      case BuiltInAction.ttsQ:
      case BuiltInAction.ttsA:
      case BuiltInAction.ttsTips:
        return Icons.record_voice_over;
      case BuiltInAction.playQ:
      case BuiltInAction.playA:
      case BuiltInAction.playTips:
        return Icons.play_circle_outline;
    }
  }

  I18nKey get labelKey {
    switch (this) {
      case BuiltInAction.deleteVerse:
        return I18nKey.deleteCurrentVerse;
      case BuiltInAction.ttsNote:
        return I18nKey.ttsNoteAction;
      case BuiltInAction.ttsQ:
        return I18nKey.ttsQAction;
      case BuiltInAction.ttsA:
        return I18nKey.ttsAAction;
      case BuiltInAction.ttsTips:
        return I18nKey.ttsTipsAction;
      case BuiltInAction.playQ:
        return I18nKey.playQAction;
      case BuiltInAction.playA:
        return I18nKey.playAAction;
      case BuiltInAction.playTips:
        return I18nKey.playTipsAction;
    }
  }
}

/// 辅助触控依附于复习页：它的所有动作都要用到当前正在复习的小节，
/// 所以跟 expandSheet/bookEditor 一样，由 RepeatLogic 直接持有一份实例，
/// 不做成全局单例，也不用自己判断"复习会话是否还在"。
class AssistiveTouchLogic {
  final RepeatLogic repeatLogic;

  AssistiveTouchLogic(this.repeatLogic);

  final enabled = false.obs;
  final posX = (-1.0).obs;
  final posY = (-1.0).obs;
  final dragging = false.obs;
  final collapsed = false.obs;
  final actions = <AssistiveTouchAction>[].obs;

  // 默认只显示"删除当前节"，TTS-*/Play-* 几个要用户自己从"新增"里加进来。
  final visibleBuiltins = <BuiltInAction>{BuiltInAction.deleteVerse}.obs;
  Size? _lastScreenSize;
  Timer? _idleTimer;
  static const idleCollapseDelay = Duration(seconds: 5);

  /// 有交互（点开/拖动/从收起状态恢复）时调用：展开，并重新开始 5 秒静置倒计时，
  /// 时间到了就收成窄杠，尽量少挡主界面。
  void noteInteraction() {
    collapsed.value = false;
    _idleTimer?.cancel();
    _idleTimer = Timer(idleCollapseDelay, () {
      collapsed.value = true;
    });
  }

  void dispose() {
    _idleTimer?.cancel();
  }

  /// posX/posY 存的是绝对像素坐标，横竖屏切换时屏幕宽高会互换，直接拿旧坐标在新屏幕上
  /// clamp 只能保证不越界，但视觉上会"跳"到不对的位置。这里按屏幕切换前"贴左边还是贴右边"
  /// 以及纵向位置占屏幕高度的比例，重新换算成新屏幕尺寸下的坐标，贴边关系和纵向相对位置保持不变。
  void reconcilePosition(Size screenSize, double buttonSize) {
    final oldSize = _lastScreenSize;
    if (oldSize != null && oldSize != screenSize && posX.value >= 0 && posY.value >= 0) {
      final wasRight = posX.value > (oldSize.width - buttonSize) / 2;
      final oldRangeY = oldSize.height - buttonSize;
      final yFraction = oldRangeY > 0 ? (posY.value / oldRangeY).clamp(0.0, 1.0) : 0.0;
      final newX = wasRight ? screenSize.width - buttonSize : 0.0;
      final newY = yFraction * (screenSize.height - buttonSize);
      posX.value = newX;
      posY.value = newY;
      savePosition(newX, newY);
    }
    _lastScreenSize = screenSize;
  }

  // 辅助触控是跟着"这堂课"走的设置(不同课堂可能想要不同的开关/位置/常用动作)，
  // 所以存到按 classroomId 分开的 CrKv，而不是全局唯一的 Kv。
  Future<void> loadSettings() async {
    enabled.value = (await Db().db.crKvDao.getInt(Classroom.curr, CrK.assistiveTouchEnabled)) == 1;
    posX.value = double.tryParse(await Db().db.crKvDao.getStr(Classroom.curr, CrK.assistiveTouchPosX) ?? '') ?? -1;
    posY.value = double.tryParse(await Db().db.crKvDao.getStr(Classroom.curr, CrK.assistiveTouchPosY) ?? '') ?? -1;
    final storedBuiltins = await Db().db.crKvDao.getStr(Classroom.curr, CrK.assistiveTouchVisibleBuiltins);
    if (storedBuiltins == null) {
      visibleBuiltins.assignAll({BuiltInAction.deleteVerse});
    } else {
      visibleBuiltins.assignAll(storedBuiltins.split(',').where((s) => s.isNotEmpty).map((s) => BuiltInAction.values.byName(s)));
    }
    await loadActions();
    noteInteraction();
  }

  Future<void> setBuiltInVisible(BuiltInAction action, bool visible) async {
    if (visible) {
      visibleBuiltins.add(action);
    } else {
      visibleBuiltins.remove(action);
    }
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.assistiveTouchVisibleBuiltins, visibleBuiltins.map((e) => e.name).join(',')));
  }

  Future<void> loadActions() async {
    actions.assignAll(await Db().db.assistiveTouchActionDao.findAll());
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.assistiveTouchEnabled, value ? '1' : '0'));
  }

  Future<void> savePosition(double x, double y) async {
    posX.value = x;
    posY.value = y;
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.assistiveTouchPosX, x.toString()));
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.assistiveTouchPosY, y.toString()));
  }

  Future<void> deleteAction(AssistiveTouchAction action) async {
    if (action.id == null) {
      return;
    }
    await Db().db.assistiveTouchActionDao.deleteById(action.id!);
    await loadActions();
  }

  /// 考查（RepeatFlowForExamine）是按计划推进的队列，没有可前后浏览的"上一个/下一个"，
  /// 所以"删除当前节"只在浏览（RepeatFlowForBrowse）等有稳定顺序的模式下开放；
  /// 其它内置动作（TTS-*/Play-*）不挑复习模式，随时都能显示。
  bool _builtInAvailableForFlow(BuiltInAction action) {
    if (action == BuiltInAction.deleteVerse) {
      final flow = repeatLogic.repeatFlow;
      return flow != null && flow is! RepeatFlowForExamine;
    }
    return true;
  }

  /// 当前模式支持、且用户没有把它从自定义菜单里移除的内置动作，按定义顺序排列。
  List<BuiltInAction> get shownBuiltins => BuiltInAction.values.where((a) => _builtInAvailableForFlow(a) && visibleBuiltins.contains(a)).toList();

  /// 当前模式支持、但被用户移除了的内置动作——"新增"选择框里可以把它们重新加回来。
  List<BuiltInAction> get addableBuiltins => BuiltInAction.values.where((a) => _builtInAvailableForFlow(a) && !visibleBuiltins.contains(a)).toList();

  bool get canDeleteCurrentVerse => shownBuiltins.contains(BuiltInAction.deleteVerse);

  Future<void> executeBuiltIn(BuiltInAction action) async {
    switch (action) {
      case BuiltInAction.deleteVerse:
        await deleteCurrentVerse();
        break;
      case BuiltInAction.ttsNote:
      case BuiltInAction.ttsQ:
      case BuiltInAction.ttsA:
      case BuiltInAction.ttsTips:
      case BuiltInAction.playQ:
      case BuiltInAction.playA:
      case BuiltInAction.playTips:
        // 先占位，还没实现，点了没有任何反应。
        break;
    }
  }

  Future<void> deleteCurrentVerse() async {
    if (!canDeleteCurrentVerse) {
      return;
    }
    final flow = repeatLogic.repeatFlow;
    final curr = flow?.currVerse;
    if (flow == null || curr == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    final verseId = curr.verseId;
    final ok = await Db().db.verseDao.delete(verseId);
    if (!ok) {
      return;
    }
    if (flow is! RepeatFlowForBrowse) {
      Get.back();
      return;
    }
    final removedIndex = flow.index;
    // flow.scheduled 可能是只读的惰性列表（LazyVerseTodayPrgList），不能原地 removeWhere，
    // 所以用一份新的可变列表整体替换，而不是修改原列表。
    final newScheduled = flow.scheduled.where((v) => v.verseId != verseId).toList();
    if (newScheduled.isEmpty) {
      Get.back();
      return;
    }
    flow.scheduled = newScheduled;
    // 删除当前段后退到上一段；如果删的就是第一段，则停在新的第一段。
    var newIndex = removedIndex > 0 ? removedIndex - 1 : 0;
    if (newIndex > newScheduled.length - 1) {
      newIndex = newScheduled.length - 1;
    }
    flow.index = newIndex;
    flow.refresh();
    await flow.gameHelper.tryRefresh(flow.currVerse!);
    repeatLogic.update([RepeatLogic.id]);
  }

  Future<void> executeAction(AssistiveTouchAction action) async {
    final verse = repeatLogic.state.helper.getCurrVerse();
    final map = repeatLogic.state.helper.getCurrVerseMap();
    if (verse == null || map == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    final logic = ExpandLogic();
    await logic.loadSettings();
    logic.bookId = verse.bookId;
    logic.verseId = verse.verseId;
    logic.verseMap = map;
    logic.sourceIndex.value = action.sourceIndex;
    logic.targetIndex.value = action.targetIndex;
    logic.enableAudio.value = action.enableAudio;
    logic.addToNextVerse.value = action.addToNextVerse;
    // instructionText 不是固定字符串：用保存的 templateIndex 对当前小节的来源文本重新渲染模版，
    // 这样同一个预设对不同小节执行时取的是各自的文本，而不是创建预设那一刻冻结的内容。
    final renderedList = repeatLogic.copyLogic.getShowText(logic.getSourceText());
    final instructionText = renderedList.isEmpty ? '' : renderedList[action.templateIndex.clamp(0, renderedList.length - 1)];
    await logic.startTask(instructionText, closeOnSuccess: false);
  }
}
