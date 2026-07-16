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
  static Future<void> open(AssistiveTouchLogic logic) async {
    await logic.loadActions();
    return Sheet.showBottomSheet(
      Get.context!,
      Obx(() {
        final canEdit = logic.repeatLogic.state.helper.getCurrVerse() != null;
        return ListView(
          shrinkWrap: true,
          children: [
            RowWidget.buildSwitch(
              title: I18nKey.assistiveTouch.tr,
              value: logic.enabled,
              set: (v) => logic.setEnabled(v),
            ),
            RowWidget.buildDividerWithoutColor(),
            RowWidget.buildText(I18nKey.customizeMenu.tr),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  if (logic.canDeleteCurrentVerse)
                    AssistiveTouchTile.build(
                      icon: Icons.delete_outline,
                      label: I18nKey.deleteCurrentVerse.tr,
                    ),
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
                    onTap: () => _addAction(logic),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(I18nKey.assistiveTouch.tr),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.6,
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
}
