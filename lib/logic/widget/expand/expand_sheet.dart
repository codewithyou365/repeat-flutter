import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/widget/text_template.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'expand_logic.dart';

class ExpandSheet {
  final logic = ExpandLogic();
  late TextTemplate copyLogic;

  void init(TextTemplate copyLogic) {
    this.copyLogic = copyLogic;
  }

  Future<void> open(String text, VerseTodayPrg verse, Map<String, dynamic> verseMap) async {
    final templateString = copyLogic.read(0);
    final template = Template(templateString, htmlEscapeValues: false);
    logic.bookId = verse.bookId;
    logic.verseId = verse.verseId;
    logic.verseMap = verseMap;
    logic.textController.text = template.renderString({'text': text});
    return Sheet.showBottomSheet(
      Get.context!,
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText("扩展助手配置"),
          RowWidget.buildDivider(),
        ],
      ),
      ListView(
        shrinkWrap: true,
        children: [
          RowWidget.buildText("在此编辑发送给助手的指令"),
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
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "在此编辑发送给助手的指令...",
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
                              var result = await copyLogic.show(TextTemplateMode.get, Get.context!, text);
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
            title: "附加位置",
            options: logic.targetOptions,
            value: logic.targetIndex.value,
            changed: (index) => logic.targetIndex.value = index,
            disabled: logic.disabled,
          ),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildSwitch(
            title: "同步生成音频",
            value: logic.enableAudio,
            disabled: logic.disabled,
          ),
          RowWidget.buildDividerWithoutColor(),

          Obx(() {
            if (logic.status.value == ExpandStatus.init) {
              return RowWidget.buildButtons([
                Button("开始执行", () {
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
                Button("关闭日志", () {
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
