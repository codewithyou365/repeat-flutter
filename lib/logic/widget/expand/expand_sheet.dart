import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/assistive_touch_action.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/text_template.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'expand_logic.dart';

class ExpandSheet {
  final logic = ExpandLogic();
  late TextTemplate copyLogic;

  void init(TextTemplate copyLogic) {
    this.copyLogic = copyLogic;
    logic.loadSettings();
  }

  String _renderTemplate(int index) {
    final list = copyLogic.getShowText(logic.getSourceText());
    if (list.isEmpty) {
      return '';
    }
    return list[index.clamp(0, list.length - 1)];
  }

  Future<void> open(VerseTodayPrg verse, Map<String, dynamic> verseMap, {AssistiveTouchAction? preset}) async {
    logic.bookId = verse.bookId;
    logic.verseId = verse.verseId;
    logic.verseMap = verseMap;
    if (preset != null) {
      logic.editingActionId = preset.id;
      logic.actionSort = preset.sort;
      logic.sourceIndex.value = preset.sourceIndex.clamp(0, logic.sourceOptions.length - 1);
      logic.targetIndex.value = preset.targetIndex.clamp(0, logic.targetOptions.length - 1);
      logic.enableAudio.value = preset.enableAudio;
      logic.behavior.value = ExpandBehavior.values[preset.behavior.clamp(0, ExpandBehavior.values.length - 1)];
      logic.templateIndex.value = preset.templateIndex;
      logic.textController.text = _renderTemplate(preset.templateIndex);
    } else {
      logic.editingActionId = null;
      logic.actionSort = DateTime.now().millisecondsSinceEpoch;
      logic.templateIndex.value = 0;
      logic.textController.text = _renderTemplate(0);
    }
    logic.reset();
    return Sheet.showBottomSheet(
      Get.context!,
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(I18nKey.expandAssistant.tr),
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
              I18nKey.serviceUrl.tr,
              logic.serviceUrl,
              onTextModify: () async {
                await logic.saveServiceUrl();
                Get.back();
              },
            );
          }),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildCupertinoPicker(
            title: I18nKey.instructionTemplate.tr,
            options: logic.sourceOptions,
            value: logic.sourceIndex.value,
            changed: (index) {
              logic.sourceIndex.value = index;
              logic.templateIndex.value = 0;
              logic.textController.text = _renderTemplate(0);
            },
            disabled: logic.disabled,
          ),
          RowWidget.buildCard(
            Obx(() {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 40, 8),
                    child: TextField(
                      controller: logic.textController,
                      maxLines: 5,
                      enabled: logic.isInit.value,
                      readOnly: true,
                      minLines: 1,
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
                    child: IconButton(
                      icon: const Icon(Icons.auto_fix_high, size: 20),
                      onPressed: logic.isInit.value
                          ? () async {
                              var result = await copyLogic.show(
                                TextTemplateMode.editAndGet,
                                Get.context!,
                                logic.getSourceText(),
                                onSelectIndex: (i) => logic.templateIndex.value = i,
                              );
                              if (result.isNotEmpty) {
                                logic.textController.text = result;
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              );
            }),
          ),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildCupertinoPicker(
            title: I18nKey.targetPosition.tr,
            options: logic.targetOptions,
            value: logic.targetIndex.value,
            changed: (index) {
              logic.targetIndex.value = index;
            },
            disabled: logic.disabled,
          ),
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
              return RowWidget.buildButtons([
                Button(I18nKey.testExecution.tr, () {
                  logic.execute(logic.textController.text);
                }),
                Button(I18nKey.btnOk.tr, () async {
                  final name = await MsgBox.password(I18nKey.assistiveTouchActionName.tr, I18nKey.assistiveTouchActionName.tr);
                  if (name == null || name.trim().isEmpty) {
                    return;
                  }
                  await logic.saveAsAction(name.trim());
                  Get.back();
                }),
              ]);
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
}
