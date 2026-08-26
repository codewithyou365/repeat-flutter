import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_logic.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/at_action.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_input_sheet.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_logic.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 新增/编辑一个悬浮球动作的表单。
///
/// 第一项永远是名字，第二项是类型——类型决定格子上的图标，也决定下面还有哪几项参数。
/// 以前的"选择动作"那一层没有了：新增就直接开这张表单，内置动作和自定义动作是同一种东西。
///
/// 表单全程改的是 [preset] 的一份副本，点了"保存"才回写，中途划走不落库。
/// 只有"类型"和"名字"是响应式的：类型换了下面整段参数要跟着换，名字改了那一行要刷新；
/// 其余参数直接写进副本，不能用 Rx——外层 Obx 一旦监听到它们，滚一格选择器就整张表重建，
/// 选择器的滚动控制器会被重新创建，滚轮会跟手指打架。
class AtActionSheet {
  static Future<bool> open(AssistiveTouchLogic logic, {AtAction? preset}) async {
    final action = _copy(preset ?? AtAction.create(AtActionType.play));
    _normalize(action);

    final name = action.name.obs;
    final type = action.type.obs;
    final enableAudio = action.net.enableAudio.obs;

    // 服务地址是全局的（所有 net 动作共用一份），单独存在 Kv 里，不进动作。
    final expand = ExpandLogic();
    await expand.loadSettings();

    final saved = await Sheet.showBottomSheet<bool>(
      Get.context!,
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(preset != null ? preset.name : I18nKey.customAction.tr),
          RowWidget.buildDivider(),
        ],
      ),
      // 两个模版的 TextEditingController 交给这个 State 管理：它的 dispose() 只在弹框真正
      // 从树上卸载时（关闭动画播完之后）才会触发，不会像手动 dispose 那样在 Get.back() 那一刻
      // 就把还在关闭动画里的 TextField 手上的 controller 拆掉（会崩），也不会因为不 dispose 而泄漏。
      _TemplateScope(
        initialText: action.net.template,
        initialTtsText: _ttsTemplateOf(action),
        builder: (template, ttsTemplate) => Obx(() {
          final currType = type.value;
          final targets = AtAction.targetsOf(currType, VerseField.maxTip);
          var targetPos = targets.indexOf(action.target);
          if (targetPos < 0) {
            targetPos = 0;
          }
          return ListView(
            shrinkWrap: true,
            children: [
              // buildTextWithEdit 里的输入框自己不会刷新显示，也不会关弹框（MsgBox.strInputWithYesOrNo
              // 传了 yes 回调时就交给回调自己 Get.back()），所以外面要包 Obx、回调里要自己关。
              Obx(() {
                return RowWidget.buildTextWithEdit(
                  I18nKey.assistiveTouchActionName.tr,
                  name,
                  onTextModify: () => Get.back(),
                );
              }),
              RowWidget.buildDividerWithoutColor(),
              RowWidget.buildCupertinoPicker(
                // 换类型时下面整段参数都换掉，选择器的 initialItem 只在建滚动控制器那一下生效，
                // 不给 key 的话滚轮会停在上一个类型的位置上。
                key: const ValueKey('type'),
                title: I18nKey.actionType.tr,
                options: AtActionType.values.map((e) => e.labelKey.tr).toList(),
                // 标题短、选项长（"删除当前节"/"Delete current verse"），默认的 80.w 放不下。
                pickWidth: 200,
                value: currType.index,
                changed: (index) {
                  action.type = AtActionType.values[index];
                  // 换类型后老的作用位置/秒数可能不在新类型的候选里（比如朗读的"笔记"换到播放），
                  // 落回合法值，免得存下一个这个类型根本不认的值。
                  _normalize(action);
                  type.value = action.type;
                },
              ),
              if (currType.hasTarget) ...[
                RowWidget.buildDividerWithoutColor(),
                RowWidget.buildCupertinoPicker(
                  key: ValueKey('target-${currType.code}'),
                  title: I18nKey.targetPosition.tr,
                  pickWidth: 200,
                  options: targets.map((e) => logic.targetLabel(currType, e)).toList(),
                  value: targetPos,
                  changed: (index) => action.target = targets[index],
                ),
              ],
              if (currType == AtActionType.tts) ...[
                RowWidget.buildDividerWithoutColor(),
                // 朗读什么由用户自己写，跟 net 的指令一个写法：可以把几个字段拼在一句话里，
                // 也可以夹自己的话（"请跟读："），不再只能挑一个字段。
                _templateCard(
                  controller: ttsTemplate,
                  hintKey: I18nKey.ttsContent,
                  items: _placeholderItems(logic, forTts: true),
                ),
                RowWidget.buildDividerWithoutColor(),
                // TTS 参数改一项存一项，直接写回这份副本；引擎/语言/音色只落在当前平台那一套上，
                // 另一个平台存着的原样留着（不同手机的引擎表根本对不上）。
                RowWidget.buildSelect(
                  title: I18nKey.ttsSettings.tr,
                  leading: const Icon(Icons.record_voice_over),
                  onTap: () async {
                    await logic.repeatLogic.ttsHelper.openWith(
                      action.tts.settings,
                      (s) async => action.tts.apply(s),
                    );
                  },
                ),
              ],
              if (currType.hasSeconds) ...[
                RowWidget.buildDividerWithoutColor(),
                _secondsPicker(action),
              ],
              if (currType == AtActionType.adjust) ..._adjustWidgets(action),
              if (currType == AtActionType.net)
                ..._netWidgets(
                  logic: logic,
                  action: action,
                  expand: expand,
                  template: template,
                  enableAudio: enableAudio,
                ),
              RowWidget.buildDividerWithoutColor(),
              RowWidget.buildButtons([
                Button(I18nKey.save.tr, () async {
                  if (name.value.trim().isEmpty) {
                    Snackbar.show(I18nKey.labelActionNameEmpty.tr);
                    return;
                  }
                  action.name = name.value.trim();
                  action.net.template = template.text;
                  action.tts.template = ttsTemplate.text;
                  action.net.enableAudio = enableAudio.value;
                  await logic.saveAction(action);
                  Get.back(result: true);
                }),
              ]),
            ],
          );
        }),
      ),
      rate: 1,
    );
    return saved ?? false;
  }

  /// 把作用位置和秒数收回到当前类型认的范围里。换类型和打开表单时各走一次，
  /// 这样构建界面时不用再改状态（在 build 里写 Rx 会引发重建循环）。
  static void _normalize(AtAction action) {
    if (action.type.hasTarget) {
      // 表单里一律列满 8 条提示：这一节提示少不代表别的节也少，
      // 按当前节的条数裁掉会把用户配好的"提示5"悄悄改成别的字段。
      final targets = AtAction.targetsOf(action.type, VerseField.maxTip);
      if (!targets.contains(action.target)) {
        action.target = targets.first;
      }
    }
    if (!_secondsOptionsOf(action.type).contains(action.seconds)) {
      action.seconds = action.type == AtActionType.rewind ? AtAction.defaultRewindSeconds : 0;
    }
    if (!AtAction.offsetMsOptions.contains(action.offsetMs)) {
      action.offsetMs = AtAction.defaultOffsetMs;
    }
    action.edge = AtAdjustEdge.fromIndex(action.edge).index;
  }

  /// rewind 退 0 秒没有意义，所以它的档位里不给 0；
  /// playPause 的 0 是"不后退，原地接着播"，要留着。
  static List<int> _secondsOptionsOf(AtActionType type) {
    if (type == AtActionType.rewind) {
      return AtAction.secondsOptions.where((e) => e > 0).toList();
    }
    return AtAction.secondsOptions;
  }

  static Widget _secondsPicker(AtAction action) {
    final options = _secondsOptionsOf(action.type);
    return RowWidget.buildCupertinoPicker(
      key: ValueKey('seconds-${action.type.code}'),
      title: action.type == AtActionType.rewind ? I18nKey.seekBackSeconds.tr : I18nKey.playPauseBackSeconds.tr,
      options: options.map((e) => '$e').toList(),
      value: options.indexOf(action.seconds),
      changed: (index) => action.seconds = options[index],
    );
  }

  /// "调整时间"的两个参数：调哪一头、挪多少毫秒。
  /// 毫秒数带正负号显示——档位里没有 0，符号是这项唯一要看的信息（负数往前借、正数往后让）。
  static List<Widget> _adjustWidgets(AtAction action) {
    const options = AtAction.offsetMsOptions;
    return [
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildCupertinoPicker(
        key: const ValueKey('edge'),
        title: I18nKey.adjustEdge.tr,
        pickWidth: 200,
        options: AtAdjustEdge.values.map((e) => e.labelKey.tr).toList(),
        value: AtAdjustEdge.fromIndex(action.edge).index,
        changed: (index) => action.edge = index,
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildCupertinoPicker(
        key: const ValueKey('offsetMs'),
        title: I18nKey.adjustOffsetMs.tr,
        options: options.map((e) => e > 0 ? '+$e' : '$e').toList(),
        value: options.indexOf(action.offsetMs),
        changed: (index) => action.offsetMs = options[index],
      ),
    ];
  }

  static List<Widget> _netWidgets({
    required AssistiveTouchLogic logic,
    required AtAction action,
    required ExpandLogic expand,
    required TextEditingController template,
    required RxBool enableAudio,
  }) {
    return [
      RowWidget.buildDividerWithoutColor(),
      Obx(() {
        return RowWidget.buildTextWithEdit(
          I18nKey.serviceUrl.tr,
          expand.serviceUrl,
          onTextModify: () async {
            await expand.saveServiceUrl();
            Get.back();
          },
        );
      }),
      RowWidget.buildDividerWithoutColor(),
      // 指令模版由用户自己写：{{question}}/{{answer}}/{{tip1}}.. 取当前小节的正文，
      // {{input1}}..{{input10}} 是执行前弹框填的参数（要几个由模版里写到第几个决定）。
      _templateCard(
        controller: template,
        hintKey: I18nKey.instruction,
        items: _placeholderItems(logic),
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildSwitch(
        title: I18nKey.generateAudio.tr,
        value: enableAudio,
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildCupertinoPicker(
        key: const ValueKey('behavior'),
        title: I18nKey.behavior.tr,
        titleOnTop: true,
        options: [
          I18nKey.behaviorOverwrite.tr,
          I18nKey.behaviorPlayOrOverwrite.tr,
        ],
        value: action.net.behavior.clamp(0, ExpandBehavior.values.length - 1),
        changed: (index) => action.net.behavior = index,
      ),
      RowWidget.buildDividerWithoutColor(),
      // 拷一条跟 App 发的一模一样的请求，方便直接对助手服务调试。
      RowWidget.buildSelect(
        title: I18nKey.copyCurl.tr,
        leading: const Icon(Icons.terminal),
        onTap: () async {
          expand.verseMap = logic.repeatLogic.state.helper.getCurrVerseMap() ?? {};
          expand.enableAudio.value = enableAudio.value;
          expand.targetRef.value = action.target;
          final numbers = ExpandLogic.inputNumbersOf(template.text);
          var values = const <String>[];
          if (numbers.isNotEmpty) {
            final input = await ExpandInputSheet.open(I18nKey.copyCurl.tr, numbers);
            if (input == null) {
              return;
            }
            values = input;
          }
          final instruction = expand.render(template.text, inputs: ExpandLogic.inputsOf(numbers, values));
          await Clipboard.setData(ClipboardData(text: expand.toCurl(instruction)));
          Snackbar.show(I18nKey.labelCopiedToClipboard.tr);
        },
      ),
    ];
  }

  /// 一个可以自由录入的模版框：右上角的「插入」菜单往光标处塞 {{xxx}}。
  /// net 的指令和朗读的文本共用这一个（两边的差别只在提示文案和菜单里有哪几项）。
  static Widget _templateCard({
    required TextEditingController controller,
    required I18nKey hintKey,
    required List<PopupMenuEntry<String>> items,
  }) {
    return RowWidget.buildCard(
      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 40, 8),
            child: TextField(
              controller: controller,
              maxLines: 8,
              minLines: 3,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintKey.tr,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: PopupMenuButton<String>(
              tooltip: I18nKey.insertParameter.tr,
              icon: const Icon(Icons.add, size: 20),
              itemBuilder: (_) => items,
              onSelected: (key) => _insertPlaceholder(controller, key),
            ),
          ),
        ],
      ),
    );
  }

  /// 朗读文本框里一开始显示什么。写过模版就用模版；没写过（老动作，那会儿朗读是挑字段的）
  /// 就按它原来的作用位置翻成等价的占位符，这样打开表单存一次，行为跟以前完全一样。
  static String _ttsTemplateOf(AtAction action) {
    if (action.tts.template.isNotEmpty) {
      return action.tts.template;
    }
    if (action.target == atCurrentTarget) {
      return '{{${ExpandLogic.currentKey}}}';
    }
    switch (QaType.fromAcronym(VerseField.baseOf(action.target))) {
      case QaType.question:
        return '{{${ExpandLogic.questionKey}}}';
      case QaType.answer:
        return '{{${ExpandLogic.answerKey}}}';
      case QaType.note:
        return '{{${ExpandLogic.noteKey}}}';
      case QaType.tip:
        return '{{${ExpandLogic.tipKey(VerseField.indexOf(action.target))}}}';
      default:
        return '{{${ExpandLogic.currentKey}}}';
    }
  }

  /// 把 {{xxx}} 插到指令框的光标处（选中了一段就替换掉），插完光标停在它后面。
  /// 指令框没获过焦时 selection 是无效的（offset 为 -1），这时追加到末尾。
  static void _insertPlaceholder(TextEditingController controller, String key) {
    final text = controller.text;
    final selection = controller.selection;
    var start = selection.start;
    var end = selection.end;
    if (start < 0 || end < 0 || start > text.length || end > text.length) {
      start = text.length;
      end = text.length;
    }
    final token = '{{$key}}';
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  /// 「插入」菜单里的条目：本节字段（显示课堂里定义的提示名）+ 执行前填的参数。
  /// [forTts] 是朗读那个框：多两项——「当前提示」（跟着界面上开着的 tab 走）和笔记，
  /// 这两样 net 用不上（net 要把结果写回一个固定字段，笔记也不在它的作用位置里）。
  static List<PopupMenuEntry<String>> _placeholderItems(AssistiveTouchLogic logic, {bool forTts = false}) {
    return [
      if (forTts) PopupMenuItem(value: ExpandLogic.currentKey, child: Text('${I18nKey.targetCurrentTip.tr}  {{${ExpandLogic.currentKey}}}')),
      PopupMenuItem(value: ExpandLogic.questionKey, child: Text('${QaType.question.i18n.tr}  {{${ExpandLogic.questionKey}}}')),
      PopupMenuItem(value: ExpandLogic.answerKey, child: Text('${QaType.answer.i18n.tr}  {{${ExpandLogic.answerKey}}}')),
      if (forTts) PopupMenuItem(value: ExpandLogic.noteKey, child: Text('${QaType.note.i18n.tr}  {{${ExpandLogic.noteKey}}}')),
      for (var i = 0; i < VerseField.maxTip; i++) PopupMenuItem(value: ExpandLogic.tipKey(i), child: Text('${logic.tipLabel(i)}  {{${ExpandLogic.tipKey(i)}}}')),
      for (var n = 1; n <= ExpandLogic.maxInput; n++) PopupMenuItem(value: ExpandLogic.inputKeyOf(n), child: Text('{{${ExpandLogic.inputKeyOf(n)}}}')),
    ];
  }

  /// 编辑时 id 要沿用原来的（手柄绑定和游戏脚本都按 id 引用这个动作）。
  static AtAction _copy(AtAction src) {
    return AtAction(
      id: src.id,
      name: src.name,
      type: src.type,
      target: src.target,
      seconds: src.seconds,
      edge: src.edge,
      offsetMs: src.offsetMs,
      tts: AtTtsConfig.fromJson(src.tts.toJson()),
      net: AtNetParams.fromJson(src.net.toJson()),
    );
  }
}

/// 把 template 的 TextEditingController 生命周期绑定到这个 State：
/// initState 建、dispose 拆，State.dispose 只在 element 真正从树上卸载（弹框关闭动画播完之后，
/// NavigatorState.finalizeRoute 那一步）才会触发，正好卡在既不早拆（动画中崩）也不漏拆（内存泄漏）的时机上。
class _TemplateScope extends StatefulWidget {
  final String initialText;
  final String initialTtsText;
  final Widget Function(TextEditingController template, TextEditingController ttsTemplate) builder;

  const _TemplateScope({required this.initialText, required this.initialTtsText, required this.builder});

  @override
  State<_TemplateScope> createState() => _TemplateScopeState();
}

class _TemplateScopeState extends State<_TemplateScope> {
  late final TextEditingController template = TextEditingController(text: widget.initialText);
  late final TextEditingController ttsTemplate = TextEditingController(text: widget.initialTtsText);

  @override
  void dispose() {
    template.dispose();
    ttsTemplate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(template, ttsTemplate);
}
