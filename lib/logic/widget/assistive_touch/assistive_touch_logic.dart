import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/assistive_touch_action.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_input_sheet.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_logic.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/logic/model_media_range.dart';
import 'package:repeat_flutter/page/repeat/logic/repeat_flow_for_browse.dart';
import 'package:repeat_flutter/page/repeat/logic/repeat_flow_for_examine.dart';
import 'package:repeat_flutter/page/repeat/logic/repeat_view_for_audio.dart';
import 'package:repeat_flutter/page/repeat/logic/repeat_view_for_video.dart';
import 'package:repeat_flutter/page/repeat/repeat_logic.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 内置动作（不是用户自己配的 AssistiveTouchAction 预设）。跟自定义动作一样，可以在自定义菜单里
/// 长按移除、点"新增"时重新加回来。
enum BuiltInAction {
  playQ,
  playA,
  playTips,
  deleteVerse,
  ttsQ,
  ttsA,
  ttsTips,
  ttsNote,
  playPause,
  seekBack,
  // 一节可以挂好几条提示：ttsTips/playTips 跟着界面上选中的那一条走，
  // 下面这些是直接指定第几条的，想读第 3 条不用先切 tab。
  // 存进 CrKv 的是枚举名，只能往后加，不能改名/调顺序。
  ttsTip1,
  ttsTip2,
  ttsTip3,
  ttsTip4,
  ttsTip5,
  ttsTip6,
  ttsTip7,
  ttsTip8,
  playTip1,
  playTip2,
  playTip3,
  playTip4,
  playTip5,
  playTip6,
  playTip7,
  playTip8,
}

/// 指定第几条提示的动作：枚举名 -> 提示下标（0 基）。
const _ttsTipIndex = {
  BuiltInAction.ttsTip1: 0,
  BuiltInAction.ttsTip2: 1,
  BuiltInAction.ttsTip3: 2,
  BuiltInAction.ttsTip4: 3,
  BuiltInAction.ttsTip5: 4,
  BuiltInAction.ttsTip6: 5,
  BuiltInAction.ttsTip7: 6,
  BuiltInAction.ttsTip8: 7,
};

const _playTipIndex = {
  BuiltInAction.playTip1: 0,
  BuiltInAction.playTip2: 1,
  BuiltInAction.playTip3: 2,
  BuiltInAction.playTip4: 3,
  BuiltInAction.playTip5: 4,
  BuiltInAction.playTip6: 5,
  BuiltInAction.playTip7: 6,
  BuiltInAction.playTip8: 7,
};

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
      case BuiltInAction.playPause:
        return Icons.play_arrow;
      case BuiltInAction.seekBack:
        return Icons.replay;
      default:
        return tipIndex == null
            ? Icons.bolt
            : (_ttsTipIndex.containsKey(this) ? Icons.record_voice_over : Icons.play_circle_outline);
    }
  }

  /// 指定第几条提示的动作对应哪一条（0 基）；其它动作返回 null。
  int? get tipIndex => _ttsTipIndex[this] ?? _playTipIndex[this];

  /// TTS-* 动作对应朗读哪个字段；非 TTS 动作没有这个概念。
  /// 每条提示共用"提示"那一套 TTS 配置，所以带号的也都是 QaType.tip。
  QaType? get qaType {
    switch (this) {
      case BuiltInAction.ttsNote:
        return QaType.note;
      case BuiltInAction.ttsQ:
        return QaType.question;
      case BuiltInAction.ttsA:
        return QaType.answer;
      case BuiltInAction.ttsTips:
        return QaType.tip;
      default:
        return _ttsTipIndex.containsKey(this) ? QaType.tip : null;
    }
  }

  /// 带号的提示动作没有固定文案（要按 book 里定义的提示名字来），走 AssistiveTouchLogic.labelOf。
  I18nKey? get fixedLabelKey => tipIndex == null ? labelKey : null;

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
      case BuiltInAction.playPause:
        return I18nKey.playPauseAction;
      case BuiltInAction.seekBack:
        return I18nKey.seekBackAction;
      default:
        // 带号的提示动作只在这里兜个底（真正显示的文案见 AssistiveTouchLogic.labelOf）。
        return _ttsTipIndex.containsKey(this) ? I18nKey.ttsTipsAction : I18nKey.playTipsAction;
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

  // 默认只显示"播放/暂停""后退3s"，删除当前节/TTS-*/Play-* 几个要用户自己从"新增"里加进来。
  final visibleBuiltins = <BuiltInAction>{BuiltInAction.playPause, BuiltInAction.seekBack}.obs;
  static const defaultSeekBackSeconds = 3;
  final seekBackSeconds = defaultSeekBackSeconds.obs;
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
      visibleBuiltins.assignAll({BuiltInAction.playPause, BuiltInAction.seekBack});
    } else {
      // 存的是枚举名，代码改过(动作被删/改名、装了旧版本)时可能对不上。这里跳过不认识的名字，
      // 不能用 byName——它会抛异常，而 loadSettings 是 RepeatLogic.onInit 的一环，一抛出来
      // onInit 就中途夭折，后面的 gameLogic 等全都初始化不了，表现为复习页/游戏页整个空白。
      final nameMap = BuiltInAction.values.asNameMap();
      visibleBuiltins.assignAll(storedBuiltins.split(',').map((s) => nameMap[s]).whereType<BuiltInAction>());
    }
    seekBackSeconds.value = await Db().db.crKvDao.getInt(Classroom.curr, CrK.assistiveTouchSeekBackSeconds) ?? defaultSeekBackSeconds;
    await loadActions();
    noteInteraction();
  }

  Future<void> setSeekBackSeconds(int seconds) async {
    if (seconds <= 0) {
      seconds = defaultSeekBackSeconds;
    }
    seekBackSeconds.value = seconds;
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.assistiveTouchSeekBackSeconds, seconds.toString()));
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
    actions.assignAll(await Db().db.assistiveTouchActionDao.findAll(Classroom.curr));
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

  /// 第 i 条提示显示的名字：book 里定义了就用定义的（跟提示 tab 栏一致），没定义用序号。
  String tipLabel(int tipIndex) {
    return VerseField.tipNameOf(repeatLogic.state.helper.getCurrBookMap(), tipIndex) //
        ??
        '${I18nKey.labelTips.tr}${tipIndex + 1}';
  }

  /// 内置动作显示的文案。带号的提示动作要按 book 里定义的提示名字来
  /// （跟提示 tab 栏保持一致），没定义名字就用序号。
  String labelOf(BuiltInAction action) {
    final tipIndex = action.tipIndex;
    if (tipIndex == null) {
      return action.labelKey.tr;
    }
    final key = action.qaType == null ? I18nKey.playTipIndexAction : I18nKey.ttsTipIndexAction;
    return key.trArgs([tipLabel(tipIndex)]);
  }

  /// "新增"里 TTS-Tips / Play-Tips 只是入口：点了再选第几条，真正加进菜单的是带号的那 16 个。
  /// 它们自己不作为动作加进去（老用户菜单里已经有的仍然照旧跟着当前选中的那条走）。
  static const List<BuiltInAction> tipGateways = [BuiltInAction.ttsTips, BuiltInAction.playTips];

  /// 入口对应的 8 个带号动作，按提示顺序排列。
  List<BuiltInAction> tipActionsOf(BuiltInAction gateway) {
    final map = gateway == BuiltInAction.ttsTips ? _ttsTipIndex : _playTipIndex;
    return map.keys.toList();
  }

  /// 当前模式支持、且用户没有把它从自定义菜单里移除的内置动作，按定义顺序排列。
  List<BuiltInAction> get shownBuiltins => BuiltInAction.values.where((a) => _builtInAvailableForFlow(a) && visibleBuiltins.contains(a)).toList();

  /// "新增"选择框里的格子：还没加进菜单的普通内置动作，加上两个提示入口
  /// （8 条里还有没加的就显示，点了再选第几条）。
  List<BuiltInAction> get addableBuiltins {
    final ret = <BuiltInAction>[];
    for (final a in BuiltInAction.values) {
      if (!_builtInAvailableForFlow(a)) {
        continue;
      }
      if (a.tipIndex != null) {
        // 带号的不直接摆出来，走下面的入口。
        continue;
      }
      if (tipGateways.contains(a)) {
        if (tipActionsOf(a).any((e) => !visibleBuiltins.contains(e))) {
          ret.add(a);
        }
        continue;
      }
      if (!visibleBuiltins.contains(a)) {
        ret.add(a);
      }
    }
    return ret;
  }

  bool get canDeleteCurrentVerse => shownBuiltins.contains(BuiltInAction.deleteVerse);

  Future<void> executeBuiltIn(BuiltInAction action) async {
    switch (action) {
      case BuiltInAction.deleteVerse:
        await deleteCurrentVerse();
        break;
      case BuiltInAction.ttsNote:
        await _speak(QaType.note.acronym);
        break;
      case BuiltInAction.ttsQ:
        await _speak(QaType.question.acronym);
        break;
      case BuiltInAction.ttsA:
        await _speak(QaType.answer.acronym);
        break;
      case BuiltInAction.ttsTips:
        // 提示有好几条时读界面上当前选中的那一条。
        await _speak(repeatLogic.state.helper.currTipRef());
        break;
      case BuiltInAction.ttsTip1:
      case BuiltInAction.ttsTip2:
      case BuiltInAction.ttsTip3:
      case BuiltInAction.ttsTip4:
      case BuiltInAction.ttsTip5:
      case BuiltInAction.ttsTip6:
      case BuiltInAction.ttsTip7:
      case BuiltInAction.ttsTip8:
        await _speak(VerseField.ref(QaType.tip.acronym, action.tipIndex!));
        break;
      case BuiltInAction.playTip1:
      case BuiltInAction.playTip2:
      case BuiltInAction.playTip3:
      case BuiltInAction.playTip4:
      case BuiltInAction.playTip5:
      case BuiltInAction.playTip6:
      case BuiltInAction.playTip7:
      case BuiltInAction.playTip8:
        final ref = VerseField.ref(QaType.tip.acronym, action.tipIndex!);
        await _play((h) => h.getCurrTipRange(ref));
        break;
      case BuiltInAction.playQ:
        await _play((h) => h.getCurrQuestionRange());
        break;
      case BuiltInAction.playA:
        await _play((h) => h.getCurrAnswerRange());
        break;
      case BuiltInAction.playTips:
        await _play((h) => h.getCurrTipRange());
        break;
      case BuiltInAction.playPause:
        _activeMediaBar()?.togglePlayPause();
        break;
      case BuiltInAction.seekBack:
        _activeMediaBar()?.seekBack(seekBackSeconds.value);
        break;
    }
  }

  /// Play/暂停、后退 N 秒复用的是"当前正在显示的音频/视频视图"里已经在播的那个 MediaBar，
  /// 跟 Play-*（_playRange）不一样：它们不切字段、不重新加载，只操作现有播放器的播放状态。
  MediaBarState? _activeMediaBar() {
    final viewName = repeatLogic.state.helper.getCurrViewName();
    final view = repeatLogic.showTypeToRepeatView[viewName];
    if (view is RepeatViewForAudio) {
      return view.mediaKey.currentState;
    }
    if (view is RepeatViewForVideo) {
      return view.mediaKey.currentState;
    }
    Snackbar.show(I18nKey.labelNoContent.tr);
    return null;
  }

  /// 播放"作用位置"上已有的内容：该字段配了可用的时间区间就播那一段（字段有自己的媒体就播
  /// 自己的文件），否则退回用 TTS 朗读该字段的文本。扩展助手 ExpandBehavior.playOrOverwrite 走这里。
  Future<void> playTarget(String fieldRef) async {
    final getRange = _rangeGetterOf(fieldRef);
    final range = getRange == null ? null : getRange(_mediaRangeHelper);
    if (range != null && range.enable) {
      await _playRange(range);
      return;
    }
    await _speak(fieldRef);
  }

  MediaRange? Function(MediaRangeHelper)? _rangeGetterOf(String fieldRef) {
    switch (QaType.fromAcronym(VerseField.baseOf(fieldRef))) {
      case QaType.question:
        return (h) => h.getCurrQuestionRange();
      case QaType.answer:
        return (h) => h.getCurrAnswerRange();
      case QaType.tip:
        return (h) => h.getCurrTipRange(fieldRef);
      default:
        return null;
    }
  }

  /// 区间只跟小节内容有关，跟当前显示哪个视图无关，所以固定用音频视图那份（它一定已经 init 过）。
  MediaRangeHelper get _mediaRangeHelper => (repeatLogic.showTypeToRepeatView[RepeatViewEnum.audio.name] as RepeatViewForAudio).mediaRangeHelper;

  /// 朗读某个字段的文本。提示带下标（'t1'…）时朗读那一条，TTS 的语速语言这些
  /// 仍然共用"提示"那一套配置（不给每条提示单独存一份）。
  Future<void> _speak(String fieldRef) async {
    final map = repeatLogic.state.helper.getCurrVerseMap();
    if (map == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    final keys = QaType.fromAcronym(VerseField.baseOf(fieldRef))?.ttsKeys;
    final text = VerseField.getText(map, fieldRef);
    if (keys == null || text == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    await repeatLogic.ttsHelper.speakText(keys, text);
  }

  /// Play-* 不自己造播放器，也不直接操作某个播放器：它只是把"当前字段"临时切过去
  /// （见 _playRange），剩下的加载和播放交给该字段对应的视图按正常流程走，
  /// 这样视图、文件、MediaBar 的区间和进度条动画才是一致的。
  Future<void> _play(MediaRange? Function(MediaRangeHelper) getRange) async {
    final range = getRange(_mediaRangeHelper);
    if (range == null || !range.enable) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    await _playRange(range);
  }

  /// 放某个区间：把"当前字段"临时切成这个区间所属的字段（playFieldOverride），然后走正常的
  /// 重建流程——视图类型、播放的文件、MediaBar 的起止点都会跟着切过去，进度条也能正常跟着动。
  /// 比如 evaluate 阶段点 Play-Q：界面会从答案的音频切回问题的视频，并从 q 的起点开始播。
  Future<void> _playRange(MediaRange range) async {
    final helper = repeatLogic.state.helper;
    final lastOverride = helper.playFieldOverride;
    helper.playFieldOverride = range.fieldAcronym;
    final viewName = helper.getCurrViewName();
    if (viewName != RepeatViewEnum.audio.name && viewName != RepeatViewEnum.video.name) {
      helper.playFieldOverride = lastOverride;
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    helper.doNotPlayMedia = false;
    helper.enableReloadMedia = true;
    helper.tryToPlayMedia = true;
    repeatLogic.update([RepeatLogic.id]);
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

  /// [inputs] 传了（哪怕是空 list）就当程序级调用：不弹框，直接拿它当 input1..inputN，
  /// 不够的补空串、多的丢掉（游戏走这条，见 js_runtime 的 assistiveTouchTap）。
  /// 不传则是人点的：inputCount > 0 时弹框让用户依次填，取消就整个不执行。
  Future<void> executeAction(AssistiveTouchAction action, {List<String>? inputs}) async {
    final verse = repeatLogic.state.helper.getCurrVerse();
    final map = repeatLogic.state.helper.getCurrVerseMap();
    if (verse == null || map == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    var values = inputs;
    if (action.inputCount > 0 && values == null) {
      values = await ExpandInputSheet.open(action.name, action.inputCount);
      if (values == null) {
        return;
      }
    }
    final inputMap = ExpandLogic.inputsOf(ExpandLogic.normalizeInputs(values, action.inputCount));
    final logic = ExpandLogic();
    await logic.loadSettings();
    logic.bookId = verse.bookId;
    logic.verseId = verse.verseId;
    logic.verseMap = map;
    logic.sourceIndex.value = action.sourceIndex;
    logic.targetIndex.value = action.targetIndex;
    logic.enableAudio.value = action.enableAudio;
    logic.behavior.value = ExpandBehavior.values[action.behavior.clamp(0, ExpandBehavior.values.length - 1)];
    logic.onPlayTarget = playTarget;
    // instructionText 不是固定字符串：用保存的 templateIndex 对当前小节的来源文本重新渲染模版，
    // 这样同一个预设对不同小节执行时取的是各自的文本，而不是创建预设那一刻冻结的内容。
    final renderedList = repeatLogic.copyLogic.getShowText(logic.getSourceText(), inputs: inputMap);
    final instructionText = renderedList.isEmpty ? '' : renderedList[action.templateIndex.clamp(0, renderedList.length - 1)];
    await logic.execute(instructionText, closeOnSuccess: false);
  }
}
