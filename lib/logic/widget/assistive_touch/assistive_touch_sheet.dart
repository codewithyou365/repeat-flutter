import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_logic.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/at_action.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/at_action_sheet.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_tile.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

/// 自定义菜单：悬浮球上摆哪些动作在这里配。
/// 所有动作都是同一种东西（见 [AtAction]），点"新增"直接开表单，不再先选一层动作类别。
class AssistiveTouchSheet {
  static Future<void> open(AssistiveTouchLogic logic) async {
    await logic.loadActions();
    return Sheet.showBottomSheet(
      Get.context!,
      Obx(() {
        // actions 必须在这里读一次：下面是 LayoutBuilder，它的 builder 要到 layout 阶段才跑，
        // 那时 Obx 收集依赖的窗口已经关了，在里面读 Rx 一个都注册不上（GetX 会直接报 ObxError）。
        final actions = logic.actions.toList();
        final canEdit = logic.repeatLogic.state.helper.getCurrVerse() != null;
        return ListView(
          shrinkWrap: true,
          children: [
            RowWidget.buildText(I18nKey.customizeMenu.tr),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LayoutBuilder(builder: (context, constraints) {
                final tileWidth = AssistiveTouchTile.widthFor(constraints.maxWidth);
                return Wrap(
                  spacing: AssistiveTouchTile.spacing,
                  runSpacing: AssistiveTouchTile.spacing,
                  children: [
                    ...actions.map((action) {
                      return AssistiveTouchTile.build(
                        icon: action.type.icon,
                        label: action.name,
                        width: tileWidth,
                        enabled: canEdit,
                        onTap: () => _showActionMenu(logic, action),
                      );
                    }),
                    AssistiveTouchTile.build(
                      icon: Icons.add,
                      label: I18nKey.btnAdd.tr,
                      width: tileWidth,
                      enabled: canEdit,
                      onTap: () => AtActionSheet.open(logic),
                    ),
                  ],
                );
              }),
            ),
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

  static Future<void> _showActionMenu(AssistiveTouchLogic logic, AtAction action) async {
    await Sheet.showBottomSheet(
      Get.context!,
      ListView(
        shrinkWrap: true,
        children: [
          RowWidget.buildSelect(
            title: I18nKey.labelEdit.tr,
            leading: const Icon(Icons.edit),
            onTap: () {
              Get.back();
              AtActionSheet.open(logic, preset: action);
            },
          ),
          RowWidget.buildSelect(
            title: I18nKey.labelMove.tr,
            leading: const Icon(Icons.swap_vert),
            onTap: () {
              Get.back();
              _showMoveMenu(logic, action);
            },
          ),
          RowWidget.buildSelect(
            title: I18nKey.labelDelete.tr,
            leading: const Icon(Icons.delete),
            onTap: () {
              Get.back();
              _confirmDelete(logic, action);
            },
          ),
        ],
      ),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(action.name),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.3,
    );
  }

  static Future<void> _showMoveMenu(AssistiveTouchLogic logic, AtAction action) async {
    await Sheet.showBottomSheet(
      Get.context!,
      ListView(
        shrinkWrap: true,
        children: [
          RowWidget.buildSelect(
            title: I18nKey.labelMoveToTop.tr,
            leading: const Icon(Icons.vertical_align_top),
            onTap: () {
              Get.back();
              logic.moveToTop(action.id);
            },
          ),
          RowWidget.buildSelect(
            title: I18nKey.labelMoveUp.tr,
            leading: const Icon(Icons.arrow_upward),
            onTap: () {
              Get.back();
              logic.moveUp(action.id);
            },
          ),
          RowWidget.buildSelect(
            title: I18nKey.labelMoveDown.tr,
            leading: const Icon(Icons.arrow_downward),
            onTap: () {
              Get.back();
              logic.moveDown(action.id);
            },
          ),
          RowWidget.buildSelect(
            title: I18nKey.labelMoveToBottom.tr,
            leading: const Icon(Icons.vertical_align_bottom),
            onTap: () {
              Get.back();
              logic.moveToBottom(action.id);
            },
          ),
        ],
      ),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(action.name),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.4,
    );
  }

  static void _confirmDelete(AssistiveTouchLogic logic, AtAction action) {
    MsgBox.yesOrNo(
      title: I18nKey.labelWarning.tr,
      desc: I18nKey.labelDeleteAssistiveTouchAction.tr,
      yes: () async {
        Get.back();
        await logic.deleteAction(action);
      },
    );
  }
}
