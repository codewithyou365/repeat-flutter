import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/assistive_touch_action.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_logic.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_tile.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

class AssistiveTouchSheet {
  /// "后退"能选的秒数。只给几档常用值，比让用户自己敲数字省事，也避免敲出 0/负数。
  static const List<int> seekBackOptions = [3, 5, 10, 15, 20, 30];

  /// 存的秒数不在候选里（改过候选档位、或旧版本存的值）时退回默认档，
  /// 不能返回 -1——CupertinoPicker 的 initialItem 拿到负数会出问题。
  static int _seekBackIndex(int seconds) {
    final index = seekBackOptions.indexOf(seconds);
    if (index != -1) {
      return index;
    }
    final fallback = seekBackOptions.indexOf(AssistiveTouchLogic.defaultSeekBackSeconds);
    return fallback == -1 ? 0 : fallback;
  }

  static Future<void> open(AssistiveTouchLogic logic) async {
    await logic.loadActions();
    return Sheet.showBottomSheet(
      Get.context!,
      Obx(() {
        final canEdit = logic.repeatLogic.state.helper.getCurrVerse() != null;
        return ListView(
          shrinkWrap: true,
          children: [
            RowWidget.buildText(I18nKey.customizeMenu.tr),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ...logic.shownBuiltins.map((builtIn) {
                    return AssistiveTouchTile.build(
                      icon: builtIn.icon,
                      label: builtIn.labelKey.tr,
                      onLongPress: () => _confirmRemoveBuiltIn(logic, builtIn),
                    );
                  }),
                  ...logic.actions.map((action) {
                    return AssistiveTouchTile.build(
                      icon: Icons.bolt,
                      label: action.name,
                      enabled: canEdit,
                      onTap: () => _editAction(logic, action),
                      onLongPress: () => _confirmDelete(logic, action),
                    );
                  }),
                  AssistiveTouchTile.build(
                    icon: Icons.add,
                    label: I18nKey.btnAdd.tr,
                    enabled: canEdit,
                    onTap: () => _showAddSelector(logic),
                  ),
                ],
              ),
            ),
            // 秒数只对"后退"这一个动作有意义，没把它加进菜单时不占位置。
            if (logic.shownBuiltins.contains(BuiltInAction.seekBack)) ...[
              RowWidget.buildDividerWithoutColor(),
              RowWidget.buildCupertinoPicker(
                title: I18nKey.seekBackSeconds.tr,
                options: seekBackOptions.map((e) => '$e').toList(),
                value: _seekBackIndex(logic.seekBackSeconds.value),
                changed: (index) => logic.setSeekBackSeconds(seekBackOptions[index]),
              ),
            ],
          ],
        );
      }),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildSwitch(
            title: I18nKey.assistiveTouch.tr,
            value: logic.enabled,
            set: (v) => logic.setEnabled(v),
          ),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.75,
    );
  }

  static Future<void> _addAction(AssistiveTouchLogic logic) async {
    final repeatLogic = logic.repeatLogic;
    final verse = repeatLogic.state.helper.getCurrVerse();
    final map = repeatLogic.state.helper.getCurrVerseMap();
    if (verse == null || map == null) {
      return;
    }
    await repeatLogic.expandSheet.open(verse, map);
    await logic.loadActions();
  }

  static Future<void> _editAction(AssistiveTouchLogic logic, AssistiveTouchAction action) async {
    final repeatLogic = logic.repeatLogic;
    final verse = repeatLogic.state.helper.getCurrVerse();
    final map = repeatLogic.state.helper.getCurrVerseMap();
    if (verse == null || map == null) {
      return;
    }
    await repeatLogic.expandSheet.open(verse, map, preset: action);
    await logic.loadActions();
  }

  static void _confirmDelete(AssistiveTouchLogic logic, AssistiveTouchAction action) {
    MsgBox.yesOrNo(
      title: I18nKey.labelWarning.tr,
      desc: I18nKey.labelDeleteAssistiveTouchAction.tr,
      yes: () async {
        Get.back();
        await logic.deleteAction(action);
      },
    );
  }

  static void _confirmRemoveBuiltIn(AssistiveTouchLogic logic, BuiltInAction builtIn) {
    MsgBox.yesOrNo(
      title: I18nKey.labelWarning.tr,
      desc: I18nKey.labelRemoveDeleteVerseAction.tr,
      yes: () async {
        Get.back();
        await logic.setBuiltInVisible(builtIn, false);
      },
    );
  }

  /// 点"新增"时先给一个选择：系统自带的内置动作用格子(一行 4 个)，自定义动作单独占一整行——
  /// 内置动作文案短，格子够放；"自定义动作"是打开表单的独立入口，用整行更醒目也不会被截断。
  static Future<void> _showAddSelector(AssistiveTouchLogic logic) async {
    await Sheet.showBottomSheet(
      Get.context!,
      Obx(() {
        final addable = logic.addableBuiltins;
        return ListView(
          shrinkWrap: true,
          children: [
            if (addable.isNotEmpty) ...[
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                children: addable.map((builtIn) {
                  return AssistiveTouchTile.build(
                    icon: builtIn.icon,
                    label: builtIn.labelKey.tr,
                    width: double.infinity,
                    onTap: () {
                      Get.back();
                      logic.setBuiltInVisible(builtIn, true);
                    },
                  );
                }).toList(),
              ),
              RowWidget.buildDividerWithoutColor(),
            ],
            RowWidget.buildSelect(
              title: I18nKey.customAction.tr,
              leading: const Icon(Icons.auto_fix_high),
              onTap: () {
                Get.back();
                _addAction(logic);
              },
            ),
          ],
        );
      }),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(I18nKey.selectAction.tr),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.4,
    );
  }
}
