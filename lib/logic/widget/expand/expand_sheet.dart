import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/assistive_touch_action.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'expand_input_sheet.dart';
import 'expand_logic.dart';

class ExpandSheet {
  final logic = ExpandLogic();

  void init() {
    logic.loadSettings();
  }

  /// 把 {{xxx}} 插到指令框的光标处（选中了一段就替换掉），插完光标停在它后面。
  /// 指令框没获过焦时 selection 是无效的（offset 为 -1），这时追加到末尾。
  void _insertPlaceholder(String key) {
    final controller = logic.textController;
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

  /// 「插入」菜单里的条目：本节字段（显示 book 里定义的提示名）+ 执行前填的参数。
  List<PopupMenuEntry<String>> _placeholderItems() {
    return [
      PopupMenuItem(value: ExpandLogic.questionKey, child: Text('${QaType.question.i18n.tr}  {{${ExpandLogic.questionKey}}}')),
      PopupMenuItem(value: ExpandLogic.answerKey, child: Text('${QaType.answer.i18n.tr}  {{${ExpandLogic.answerKey}}}')),
      for (var i = 0; i < VerseField.maxTip; i++)
        PopupMenuItem(value: ExpandLogic.tipKey(i), child: Text('${logic.tipLabel(i)}  {{${ExpandLogic.tipKey(i)}}}')),
      for (var n = 1; n <= ExpandLogic.maxInput; n++)
        PopupMenuItem(value: ExpandLogic.inputKeyOf(n), child: Text('{{${ExpandLogic.inputKeyOf(n)}}}')),
    ];
  }

  Future<void> open(
    VerseTodayPrg verse,
    Map<String, dynamic> verseMap, {
    AssistiveTouchAction? preset,
  }) async {
    logic.bookId = verse.bookId;
    logic.verseId = verse.verseId;
    logic.verseMap = verseMap;
    if (preset != null) {
      logic.editingActionId = preset.id;
      logic.actionSort = preset.sort;
      logic.targetIndex.value = ExpandLogic.normalizeTargetIndex(preset.targetIndex).clamp(0, logic.targetOptions.length - 1);
      logic.enableAudio.value = preset.enableAudio;
      logic.behavior.value = ExpandBehavior.values[preset.behavior.clamp(0, ExpandBehavior.values.length - 1)];
      logic.textController.text = preset.template;
      logic.actionName.value = preset.name;
    } else {
      logic.editingActionId = null;
      logic.actionSort = DateTime.now().millisecondsSinceEpoch;
      logic.textController.text = '';
      logic.actionName.value = '';
    }
    // 标题跟上一个界面保持一致：编辑时是那个动作的名字，新增时是"自定义动作"。
    final title = preset != null ? preset.name : I18nKey.customAction.tr;
    logic.reset();
    return Sheet.showBottomSheet(
      Get.context!,
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(title),
          RowWidget.buildDivider(),
        ],
      ),
      ListView(
        shrinkWrap: true,
        children: [
          // buildTextWithEdit 里的输入框自己不会刷新显示，也不会关弹框（MsgBox.strInputWithYesOrNo
          // 传了 yes 回调时就交给回调自己 Get.back()），所以外面要包 Obx、回调里要自己关。
          Obx(() {
            return RowWidget.buildTextWithEdit(
              I18nKey.assistiveTouchActionName.tr,
              logic.actionName,
              onTextModify: () => Get.back(),
            );
          }),
          RowWidget.buildDividerWithoutColor(),
          Obx(() {
            return RowWidget.buildTextWithEdit(
              I18nKey.serviceUrl.tr,
              logic.serviceUrl,
              onTextModify: () async {
                await logic.saveServiceUrl();
                Get.back();
              },
            );
          }),
          RowWidget.buildDividerWithoutColor(),
          // 指令模版由用户自己写：{{question}}/{{answer}}/{{tip1}}.. 取当前小节的正文，
          // {{input1}}..{{input10}} 是执行前弹框填的参数（要几个由模版里写到第几个决定）。
          RowWidget.buildCard(
            Obx(() {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 40, 8),
                    child: TextField(
                      controller: logic.textController,
                      maxLines: 8,
                      enabled: logic.isInit.value,
                      minLines: 3,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: I18nKey.instruction.tr,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: PopupMenuButton<String>(
                      enabled: logic.isInit.value,
                      tooltip: I18nKey.insertParameter.tr,
                      icon: const Icon(Icons.add, size: 20),
                      itemBuilder: (_) => _placeholderItems(),
                      onSelected: _insertPlaceholder,
                    ),
                  ),
                ],
              );
            }),
          ),
          RowWidget.buildDividerWithoutColor(),
          Builder(builder: (_) {
            final values = ExpandLogic.selectableTargetIndexes;
            final labels = logic.targetOptions;
            var pos = values.indexOf(logic.targetIndex.value);
            if (pos < 0) {
              pos = 0;
            }
            return RowWidget.buildCupertinoPicker(
              title: I18nKey.targetPosition.tr,
              options: values.map((e) => labels[e]).toList(),
              value: pos,
              changed: (index) {
                logic.targetIndex.value = values[index];
              },
              disabled: logic.disabled,
            );
          }),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildSwitch(
            title: I18nKey.generateAudio.tr,
            value: logic.enableAudio,
            disabled: logic.disabledAudioWidget,
          ),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildCupertinoPicker(
            title: I18nKey.behavior.tr,
            titleOnTop: true,
            options: logic.behaviorOptions,
            value: logic.behavior.value.index,
            changed: (index) {
              logic.behavior.value = ExpandBehavior.values[index];
            },
            disabled: logic.disabled,
          ),
          RowWidget.buildDividerWithoutColor(),
          Obx(() {
            if (logic.status.value == ExpandStatus.init) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: [
                    // 名字直接在上面那行改，这里点了就存盘关界面，不再另外弹框问名字。
                    _softButton(
                      Get.context!,
                      icon: Icons.check_rounded,
                      text: I18nKey.save.tr,
                      onTap: () async {
                        if (logic.actionName.value.trim().isEmpty) {
                          Snackbar.show(I18nKey.labelActionNameEmpty.tr);
                          return;
                        }
                        await logic.saveAsAction();
                        Get.back();
                      },
                    ),
                    const SizedBox(height: 8),
                    // 拷一条跟 App 发的一模一样的请求，方便直接对助手服务调试。
                    _softButton(
                      Get.context!,
                      icon: Icons.terminal,
                      text: I18nKey.copyCurl.tr,
                      onTap: () async {
                        final template = logic.textController.text;
                        final numbers = ExpandLogic.inputNumbersOf(template);
                        var values = const <String>[];
                        if (numbers.isNotEmpty) {
                          final input = await ExpandInputSheet.open(I18nKey.copyCurl.tr, numbers);
                          if (input == null) {
                            return;
                          }
                          values = input;
                        }
                        final instruction = logic.render(template, inputs: ExpandLogic.inputsOf(numbers, values));
                        await Clipboard.setData(ClipboardData(text: logic.toCurl(instruction)));
                        Snackbar.show(I18nKey.labelCopiedToClipboard.tr);
                      },
                    ),
                  ],
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: logic.logs
                    .map(
                      (log) => Text(
                        log,
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    )
                    .toList(),
              ),
            );
          }),
          Obx(() {
            if (logic.status.value == ExpandStatus.finish) {
              return RowWidget.buildButtons([
                Button(I18nKey.closeLog.tr, () {
                  logic.reset();
                }),
              ]);
            } else {
              return SizedBox.shrink();
            }
          }),
        ],
      ),
      rate: 1,
    ).then((_) {
      logic.reset();
    });
  }

  /// 浅灰色圆角按钮，跟二维码下方的「复制」按钮同一套样式，深浅色主题都跟随 secondaryHeaderColor。
  Widget _softButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(10);
    return Material(
      color: Theme.of(context).secondaryHeaderColor,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
