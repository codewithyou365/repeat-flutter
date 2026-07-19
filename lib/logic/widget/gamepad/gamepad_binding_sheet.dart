import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/gamepad/gamepad_binding.dart';
import 'package:repeat_flutter/logic/widget/gamepad/gamepad_logic.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

/// 手柄绑定配置弹窗：仿照 AssistiveTouchSheet，分三组列出可绑定功能，点某行进入"按键捕获"改键。
class GamepadBindingSheet {
  static Future<void> open(GamepadLogic logic) async {
    // 自定义动作用于渲染第三组，先加载一次。
    await logic.repeatLogic.assistiveTouchLogic.loadActions();
    return Sheet.showBottomSheet(
      Get.context!,
      Obx(() {
        // Map.from 会经 RxMap 重写的 keys/operator[] 读取，从而向 Obx 注册监听，
        // 改键后整张列表实时刷新；同时拿到当前映射快照用于查询各功能已绑的按键。
        final current = Map<int, String>.from(logic.bindings);
        final custom = GamepadBinding.customTargets(logic.repeatLogic);
        return ListView(
          shrinkWrap: true,
          children: [
            RowWidget.buildText(I18nKey.gamepadNavGroup.tr),
            ...GamepadBinding.navTargets().map((t) => _row(logic, current, t)),
            RowWidget.buildDividerWithoutColor(),
            RowWidget.buildText(I18nKey.gamepadActionGroup.tr),
            ...GamepadBinding.builtinTargets().map((t) => _row(logic, current, t)),
            if (custom.isNotEmpty) ...[
              RowWidget.buildDividerWithoutColor(),
              RowWidget.buildText(I18nKey.customAction.tr),
              ...custom.map((t) => _row(logic, current, t)),
            ],
          ],
        );
      }),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildSwitch(
            title: I18nKey.gamepadBinding.tr,
            value: logic.enabled,
            set: (v) => logic.setEnabled(v),
          ),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.75,
    );
  }

  static Widget _row(GamepadLogic logic, Map<int, String> current, GamepadTarget target) {
    int? keyId;
    for (final entry in current.entries) {
      if (entry.value == target.descriptor) {
        keyId = entry.key;
        break;
      }
    }
    final binding = keyId == null ? I18nKey.gamepadUnbound.tr : GamepadBinding.keyLabel(keyId);
    return ListTile(
      leading: Icon(target.icon),
      title: Text(target.label),
      trailing: Text(binding, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () => _capture(logic, target),
    );
  }

  /// 弹"请按下手柄按键"对话框并进入捕获态：按下即绑定并关闭；也可清除或取消。
  static Future<void> _capture(GamepadLogic logic, GamepadTarget target) async {
    logic.beginCapture((keyId) {
      logic.bind(keyId, target.descriptor);
      Get.back();
    });
    await MsgBox.myDialog(
      title: target.label,
      barrierDismissible: false,
      content: MsgBox.content(I18nKey.gamepadPressButton.tr),
      action: MsgBox.buttonsWithDivider(
        buttons: [
          MsgBox.button(text: I18nKey.btnCancel.tr, onPressed: () => Get.back()),
          MsgBox.button(
            text: I18nKey.gamepadClearBinding.tr,
            onPressed: () {
              logic.clear(target.descriptor);
              Get.back();
            },
          ),
        ],
      ),
    );
    // 对话框以任何方式关闭后都撤销捕获态，避免关掉后下一次按键被误绑。
    logic.cancelCapture();
  }
}
