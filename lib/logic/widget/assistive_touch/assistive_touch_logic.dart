import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/at_action.dart';
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

/// 辅助触控依附于复习页：它的所有动作都要用到当前正在复习的小节，
/// 所以跟 bookEditor 一样，由 RepeatLogic 直接持有一份实例，
/// 不做成全局单例，也不用自己判断"复习会话是否还在"。
class AssistiveTouchLogic {
  final RepeatLogic repeatLogic;

  AssistiveTouchLogic(this.repeatLogic);

  final enabled = false.obs;
  final posX = (-1.0).obs;
  final posY = (-1.0).obs;
  final dragging = false.obs;
  final collapsed = false.obs;

  /// 悬浮球上的全部动作，存在 classroom.content 里，跟着课堂走。
  final actions = <AtAction>[].obs;

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

  // 开关和位置是跟着"这堂课"走的设置，存到按 classroomId 分开的 CrKv；
  // 动作列表本身存在 classroom.content 里（见 [loadActions]），跟提示的名字放在一起，
  // 这样导出/同步课堂内容时动作会跟着一起走。
  Future<void> loadSettings() async {
    enabled.value = (await Db().db.crKvDao.getInt(Classroom.curr, CrK.assistiveTouchEnabled)) == 1;
    posX.value = double.tryParse(await Db().db.crKvDao.getStr(Classroom.curr, CrK.assistiveTouchPosX) ?? '') ?? -1;
    posY.value = double.tryParse(await Db().db.crKvDao.getStr(Classroom.curr, CrK.assistiveTouchPosY) ?? '') ?? -1;
    // 动作列表不在这里读：它在课堂内容里，而课堂内容要等 Helper.init 才取到手，
    // 由 RepeatLogic 在那之后单独调一次 [loadActions]。
    noteInteraction();
  }

  /// 课堂内容那份 map。helper 在复习页初始化时已经查过一次，动作的读写都在它上面进行，
  /// 这样提示名字和动作列表共用同一份内存对象，不会互相覆盖。
  Map<String, dynamic>? get _classroomMap => repeatLogic.state.helper.getClassroomMap();

  /// 从课堂内容里读动作列表。没有 [AtAction.contentKey] 这个键（新课堂/老数据）时给一份默认的，
  /// 并立刻落库，免得每次进来都重新生成一份 id 不一样的（手柄绑定按 id 走，id 变了绑定就断）。
  Future<void> loadActions() async {
    final map = _classroomMap;
    final raw = map?[AtAction.contentKey];
    if (map == null) {
      actions.assignAll(AtAction.defaults());
      return;
    }
    if (raw is! List) {
      actions.assignAll(AtAction.defaults());
      await _saveActions();
      return;
    }
    // 认不出来的条目（装过更新的版本、内容被外部改坏）整条跳过，不能抛异常：
    // 这里在复习页初始化的路上，抛出去后面的 gameLogic 等全都初始化不了，表现为整页空白。
    actions.assignAll(raw.map(AtAction.fromJson).whereType<AtAction>());
  }

  Future<void> _saveActions() async {
    final map = _classroomMap;
    if (map == null) {
      return;
    }
    map[AtAction.contentKey] = actions.map((e) => e.toJson()).toList();
    await Db().db.classroomDao.updateContent(Classroom.curr, jsonEncode(map));
  }

  /// 新增或按 id 覆盖一条动作。
  Future<void> saveAction(AtAction action) async {
    final index = actions.indexWhere((e) => e.id == action.id);
    if (index < 0) {
      actions.add(action);
    } else {
      actions[index] = action;
    }
    actions.refresh();
    await _saveActions();
  }

  Future<void> deleteAction(AtAction action) async {
    actions.removeWhere((e) => e.id == action.id);
    await _saveActions();
  }

  Future<void> moveToTop(int actionId) async {
    final index = actions.indexWhere((e) => e.id == actionId);
    if (index <= 0) return;
    final item = actions.removeAt(index);
    actions.insert(0, item);
    await _saveActions();
  }

  Future<void> moveToBottom(int actionId) async {
    final index = actions.indexWhere((e) => e.id == actionId);
    if (index == -1 || index == actions.length - 1) return;
    final item = actions.removeAt(index);
    actions.add(item);
    await _saveActions();
  }

  Future<void> moveUp(int actionId) async {
    final index = actions.indexWhere((e) => e.id == actionId);
    if (index <= 0) return;
    final item = actions.removeAt(index);
    actions.insert(index - 1, item);
    await _saveActions();
  }

  Future<void> moveDown(int actionId) async {
    final index = actions.indexWhere((e) => e.id == actionId);
    if (index == -1 || index == actions.length - 1) return;
    final item = actions.removeAt(index);
    actions.insert(index + 1, item);
    await _saveActions();
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

  /// 考查（RepeatFlowForExamine）是按计划推进的队列，没有可前后浏览的"上一个/下一个"，
  /// 所以"删除当前节"只在浏览（RepeatFlowForBrowse）等有稳定顺序的模式下开放；
  /// 其它类型的动作不挑复习模式，随时都能显示。
  bool availableForFlow(AtAction action) {
    if (action.type == AtActionType.delete) {
      final flow = repeatLogic.repeatFlow;
      return flow != null && flow is! RepeatFlowForExamine;
    }
    return true;
  }

  /// 当前复习模式下能用的动作，按存的顺序排。
  List<AtAction> get shownActions => actions.where(availableForFlow).toList();

  /// 第 i 条提示显示的名字：课堂里定义了就用定义的（跟提示 tab 栏一致），没定义用序号。
  String tipLabel(int tipIndex) {
    return VerseField.tipNameOf(_classroomMap, tipIndex) //
        ??
        '${I18nKey.labelTips.tr}${tipIndex + 1}';
  }

  /// 作用位置在界面上显示的名字。空串是"当前"，两种类型的"当前"含义不同，见
  /// [AtActionType.currentTargetLabelKey]。
  String targetLabel(AtActionType type, String target) {
    if (target == atCurrentTarget) {
      return type.currentTargetLabelKey.tr;
    }
    final qaType = QaType.fromAcronym(VerseField.baseOf(target));
    if (qaType == null) {
      return target;
    }
    if (qaType == QaType.tip) {
      return tipLabel(VerseField.indexOf(target));
    }
    return qaType.i18n.tr;
  }

  /// 动作真正作用在哪个字段上。"当前"对播放/朗读是界面上选中的那条提示，
  /// 对后退/播放暂停是进度条现在绑着的那个字段（这两个在 [execute] 里另外处理，不走这里）。
  String _fieldRefOf(AtAction action) {
    if (action.target == atCurrentTarget) {
      return repeatLogic.state.helper.currTipRef();
    }
    return action.target;
  }

  bool get canDeleteCurrentVerse => actions.any((a) => a.type == AtActionType.delete && availableForFlow(a));

  /// [inputs] 只对 net 类型有意义，见 [_executeNet]。
  Future<void> execute(AtAction action, {List<String>? inputs}) async {
    switch (action.type) {
      case AtActionType.play:
        await _play(_fieldRefOf(action));
        break;
      case AtActionType.tts:
        await _speakWith(_fieldRefOf(action), action.tts.settings);
        break;
      case AtActionType.rewind:
        if (action.target == atCurrentTarget) {
          await _activeMediaBar()?.seekBack(action.seconds);
        } else {
          await _rewindOn(action.target, action.seconds);
        }
        break;
      case AtActionType.playPause:
        if (action.target == atCurrentTarget) {
          await _activeMediaBar()?.togglePlayPause(backSeconds: action.seconds);
        } else {
          await _playPauseOn(action.target, action.seconds);
        }
        break;
      case AtActionType.net:
        await _executeNet(action, inputs: inputs);
        break;
      case AtActionType.delete:
        await deleteCurrentVerse();
        break;
    }
  }

  /// 指定目标的"播放/暂停"：目标就是现在这条进度条绑着的字段时，跟不指定的完全一样
  /// （直接操作现有播放器）；不是的话，先把当前字段停在哪记下来（[_playRange] 负责），
  /// 再切到目标字段，从它上次停的点位（这一节还没播过就从区间起点）往回退 [backSeconds] 开始播。
  Future<void> _playPauseOn(String fieldRef, int backSeconds) async {
    if (_mediaRangeHelper.getCurrRange().fieldAcronym == fieldRef) {
      await _activeMediaBar()?.togglePlayPause(backSeconds: backSeconds);
      return;
    }
    await _switchTo(fieldRef, offsetMs: -backSeconds * 1000);
  }

  /// 指定目标的"后退 N 秒"。目标是当前字段就地后退，否则切过去接着上次的点位往回退。
  Future<void> _rewindOn(String fieldRef, int seconds) async {
    if (_mediaRangeHelper.getCurrRange().fieldAcronym == fieldRef) {
      await _activeMediaBar()?.seekBack(seconds);
      return;
    }
    await _switchTo(fieldRef, offsetMs: -seconds * 1000);
  }

  Future<void> _switchTo(String fieldRef, {int offsetMs = 0}) async {
    final range = _mediaRangeHelper.getCurrRangeOf(fieldRef);
    if (range == null || !range.enable) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    final helper = repeatLogic.state.helper;
    var at = (helper.lastPlayPosMs[fieldRef] ?? range.start) + offsetMs;
    if (at < 0) {
      at = 0;
    }
    helper.playAtMs = at;
    if (!await _playRange(range)) {
      helper.playAtMs = null;
    }
  }

  /// 播放/暂停、后退复用的是"当前正在显示的音频/视频视图"里已经在播的那个 MediaBar，
  /// 跟 play 类型（_playRange）不一样：它们不切字段、不重新加载，只操作现有播放器的播放状态。
  MediaBarState? _activeMediaBar() {
    final bar = _currMediaBar();
    if (bar == null) {
      Snackbar.show(I18nKey.labelNoContent.tr);
    }
    return bar;
  }

  /// 同上，但没有就静静返回 null（记点位这种顺手做的事不该弹提示）。
  MediaBarState? _currMediaBar() {
    final viewName = repeatLogic.state.helper.getCurrViewName();
    final view = repeatLogic.showTypeToRepeatView[viewName];
    if (view is RepeatViewForAudio) {
      return view.mediaKey.currentState;
    }
    if (view is RepeatViewForVideo) {
      return view.mediaKey.currentState;
    }
    return null;
  }

  /// 记下现在这条进度条停在哪，挂到它绑着的那个字段上。切到别的字段前调用，
  /// 这样待会"后退-<刚才那个字段>"才接得上，而不是从头再来。
  void _noteCurrPlayPos() {
    final bar = _currMediaBar();
    if (bar == null) {
      return;
    }
    repeatLogic.state.helper.lastPlayPosMs[_mediaRangeHelper.getCurrRange().fieldAcronym] = bar.currentPositionMs;
  }

  /// 播放"作用位置"上已有的内容：该字段配了可用的时间区间就播那一段（字段有自己的媒体就播
  /// 自己的文件），否则退回用 TTS 朗读该字段的文本。net 动作的 playOrOverwrite 走这里。
  Future<void> playTarget(String fieldRef) async {
    final getRange = _rangeGetterOf(fieldRef);
    final range = getRange == null ? null : getRange(_mediaRangeHelper);
    if (range != null && range.enable) {
      await _playRange(range);
      return;
    }
    await _speak(fieldRef);
  }

  /// 点正文时用：该字段配了可用区间就播那一段（等同 play 类型的动作），
  /// 没有就静静什么都不做——不退回 TTS，也不弹提示（跟 [playTarget] 的区别就在这）。
  Future<void> playFieldRangeIfAny(String fieldRef) async {
    final viewName = repeatLogic.state.helper.getCurrViewName();
    if (viewName != RepeatViewEnum.audio.name && viewName != RepeatViewEnum.video.name) {
      // 纯文本视图下没有播放器，别让 _playRange 弹"无内容"。
      return;
    }
    final getRange = _rangeGetterOf(fieldRef);
    final range = getRange == null ? null : getRange(_mediaRangeHelper);
    if (range == null || !range.enable) {
      return;
    }
    await _playRange(range);
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

  /// 朗读某个字段的文本，语速语音用按字段类型存的那套公共配置。
  /// 悬浮球的 tts 动作不走这条，走 [_speakWith]（每个动作自己带一份配置）。
  Future<void> _speak(String fieldRef) async {
    final text = _textOf(fieldRef);
    final keys = QaType.fromAcronym(VerseField.baseOf(fieldRef))?.ttsKeys;
    if (keys == null || text == null) {
      return;
    }
    await repeatLogic.ttsHelper.speakText(keys, text);
  }

  Future<void> _speakWith(String fieldRef, TtsSettings settings) async {
    final text = _textOf(fieldRef);
    if (text == null) {
      return;
    }
    await repeatLogic.ttsHelper.speakTextWith(settings, text);
  }

  /// 取字段正文，顺带把"没数据/没内容"的提示弹掉，两个朗读入口共用。
  String? _textOf(String fieldRef) {
    final map = repeatLogic.state.helper.getCurrVerseMap();
    if (map == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return null;
    }
    final text = VerseField.getText(map, fieldRef);
    if (text == null || text.isEmpty) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return null;
    }
    return text;
  }

  /// play 类型不自己造播放器，也不直接操作某个播放器：它只是把"当前字段"临时切过去
  /// （见 _playRange），剩下的加载和播放交给该字段对应的视图按正常流程走，
  /// 这样视图、文件、MediaBar 的区间和进度条动画才是一致的。
  Future<void> _play(String fieldRef) async {
    final getRange = _rangeGetterOf(fieldRef);
    final range = getRange == null ? null : getRange(_mediaRangeHelper);
    if (range == null || !range.enable) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    await _playRange(range);
  }

  /// 放某个区间：把"当前字段"临时切成这个区间所属的字段（playFieldOverride），然后走正常的
  /// 重建流程——视图类型、播放的文件、MediaBar 的起止点都会跟着切过去，进度条也能正常跟着动。
  /// 比如 evaluate 阶段播问题：界面会从答案的音频切回问题的视频，并从 q 的起点开始播。
  /// 没能切过去（目标字段不是音视频）时返回 false，什么都不改。
  Future<bool> _playRange(MediaRange range) async {
    final helper = repeatLogic.state.helper;
    // 离开当前字段前把它的点位记下来，回来时（后退到该字段）才接得上。
    _noteCurrPlayPos();
    final lastOverride = helper.playFieldOverride;
    helper.playFieldOverride = range.fieldAcronym;
    final viewName = helper.getCurrViewName();
    if (viewName != RepeatViewEnum.audio.name && viewName != RepeatViewEnum.video.name) {
      helper.playFieldOverride = lastOverride;
      Snackbar.show(I18nKey.labelNoContent.tr);
      return false;
    }
    helper.doNotPlayMedia = false;
    helper.enableReloadMedia = true;
    helper.tryToPlayMedia = true;
    repeatLogic.update([RepeatLogic.id]);
    return true;
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
  /// 不传则是人点的：模版里写了参数时弹框让用户依次填，取消就整个不执行。
  Future<void> _executeNet(AtAction action, {List<String>? inputs}) async {
    final verse = repeatLogic.state.helper.getCurrVerse();
    final map = repeatLogic.state.helper.getCurrVerseMap();
    if (verse == null || map == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    // 要哪几个参数是从模版里的 {{inputN}} 扫出来的，不再存库。
    final inputNumbers = ExpandLogic.inputNumbersOf(action.net.template);
    var values = inputs;
    if (inputNumbers.isNotEmpty && values == null) {
      values = await ExpandInputSheet.open(action.name, inputNumbers);
      if (values == null) {
        return;
      }
    }
    final inputMap = ExpandLogic.inputsOf(inputNumbers, values);
    final logic = ExpandLogic();
    await logic.loadSettings();
    logic.bookId = verse.bookId;
    logic.verseId = verse.verseId;
    logic.verseMap = map;
    logic.classroomMap = _classroomMap;
    logic.targetRef.value = action.target;
    logic.enableAudio.value = action.net.enableAudio;
    logic.behavior.value = ExpandBehavior.values[action.net.behavior.clamp(0, ExpandBehavior.values.length - 1)];
    logic.onPlayTarget = playTarget;
    // instructionText 不是固定字符串：模版里的 {{question}}/{{answer}}/{{tip1}}.. 每次都按当前小节渲染，
    // 这样同一个动作对不同小节执行时取的是各自的文本，而不是创建动作那一刻冻结的内容。
    final instructionText = logic.render(action.net.template, inputs: inputMap);
    await logic.execute(instructionText, closeOnSuccess: false);
  }

  /// 反解 input1 用的占位符。用控制字符夹着，正常的模版/正文里不会出现。
  static const String _input1Sentinel = 'input1';

  /// 这个动作上次执行时用的 input1：作用位置（比如提示1）里存着上次的指令
  /// （见 VerseField.setInstruction），拿模版反着一比就能把 input1 抠出来。
  ///
  /// 做法是先用哨兵渲染一遍模版，得到「前缀 + 哨兵 + 后缀」，再拿前后缀去掐上次的指令——
  /// 这样模版里的 {{answer}} 等其它占位符怎么渲染都不用管，它们两边渲染出来是一样的。
  ///
  /// 只认 input1（这个入口是给游戏的「单词累积提问」用的，动作按约定只有一个参数）。
  /// 不是 net 类型、没执行过、指令没存过、模版里没写 {{input1}}、模版改过对不上，都返回 null。
  String? lastInput1Of(AtAction action) {
    if (action.type != AtActionType.net) {
      return null;
    }
    final map = repeatLogic.state.helper.getCurrVerseMap();
    if (map == null) {
      return null;
    }
    final logic = ExpandLogic();
    logic.verseMap = map;
    final instruction = VerseField.getInstruction(map, action.target);
    if (instruction == null) {
      return null;
    }
    final pattern = logic.render(
      action.net.template,
      inputs: {ExpandLogic.inputKeyOf(1): _input1Sentinel},
    );
    final at = pattern.indexOf(_input1Sentinel);
    if (at < 0) {
      return null;
    }
    final prefix = pattern.substring(0, at);
    final suffix = pattern.substring(at + _input1Sentinel.length);
    if (instruction.length < prefix.length + suffix.length || !instruction.startsWith(prefix) || !instruction.endsWith(suffix)) {
      return null;
    }
    return instruction.substring(prefix.length, instruction.length - suffix.length);
  }
}
