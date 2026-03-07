import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/text_template.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
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

  Future<void> open(String text, VerseTodayPrg verse, Map<String, dynamic> verseMap) async {
    final templateString = copyLogic.getShowText(text)[0];
    logic.bookId = verse.bookId;
    logic.verseId = verse.verseId;
    logic.verseMap = verseMap;
    logic.textController.text = templateString;
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
          RowWidget.buildTextWithEdit(
            I18nKey.serviceUrl.tr,
            logic.serviceUrl,
            onTextModify: () => logic.saveServiceUrl(),
          ),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildText(I18nKey.editInstructionTips.tr),
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
                      minLines: 1,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: I18nKey.editInstructionTips.tr,
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
                              var result = await copyLogic.show(TextTemplateMode.editAndGet, Get.context!, text);
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
            title: I18nKey.appendPosition.tr,
            options: logic.targetOptions,
            value: logic.targetIndex.value,
            changed: (index) {
              logic.targetIndex.value = index;
              final qaType = logic.toQaType(index);
              if (qaType == QaType.note || qaType == QaType.tip) {
                logic.enableAudio.value = false;
                logic.disabledAudioWidget.value = true;
              } else {
                logic.disabledAudioWidget.value = false;
              }
            },
            disabled: logic.disabled,
          ),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildSwitch(
            title: I18nKey.syncGenerateAudio.tr,
            value: logic.enableAudio,
            disabled: logic.disabledAudioWidget,
          ),
          RowWidget.buildDividerWithoutColor(),
          Obx(() {
            if (logic.status.value == ExpandStatus.init) {
              return RowWidget.buildButtons([
                Button(I18nKey.startExecution.tr, () {
                  logic.startTask(logic.textController.text);
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
