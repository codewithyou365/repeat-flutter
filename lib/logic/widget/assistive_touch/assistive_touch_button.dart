import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_logic.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_tile.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

class AssistiveTouchButton extends StatelessWidget {
  static const double size = 56;
  static const double collapsedWidth = 14;
  static const double collapsedHeight = 48;
  // 窄杠可视宽度只有 14，太窄不好点，所以命中区域比它宽得多，视觉上的窄杠贴边、
  // 命中区域往屏幕内多留一截；同时用 onTapDown 而不是 onTap，手指一碰到就展开，不用等抬起。
  static const double collapsedHitWidth = 18;
  final AssistiveTouchLogic logic;

  const AssistiveTouchButton({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!logic.enabled.value) {
        return const SizedBox.shrink();
      }
      final screenSize = MediaQuery.of(context).size;
      logic.reconcilePosition(screenSize, size);
      double x = logic.posX.value;
      double y = logic.posY.value;
      if (x < 0 || y < 0) {
        x = screenSize.width - size - 12;
        y = screenSize.height - size - 160;
      }
      x = x.clamp(0.0, screenSize.width - size);
      y = y.clamp(0.0, screenSize.height - size);

      if (logic.collapsed.value) {
        final onRight = x > (screenSize.width - size) / 2;
        final hitX = onRight ? screenSize.width - collapsedHitWidth : 0.0;
        final barY = (y + size / 2 - collapsedHeight / 2).clamp(0.0, screenSize.height - collapsedHeight);
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          left: hitX,
          top: barY,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => logic.noteInteraction(),
            child: SizedBox(
              width: collapsedHitWidth,
              height: collapsedHeight,
              child: Align(
                alignment: onRight ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: collapsedWidth,
                  height: collapsedHeight,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.horizontal(
                      left: onRight ? const Radius.circular(8) : Radius.zero,
                      right: onRight ? Radius.zero : const Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return AnimatedPositioned(
        duration: logic.dragging.value ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        left: x,
        top: y,
        child: GestureDetector(
          onTap: () {
            logic.noteInteraction();
            _openMenu(logic);
          },
          onPanStart: (_) => logic.noteInteraction(),
          onPanUpdate: (details) {
            logic.posX.value = (logic.posX.value + details.delta.dx).clamp(0.0, screenSize.width - size);
            logic.posY.value = (logic.posY.value + details.delta.dy).clamp(0.0, screenSize.height - size);
          },
          onPanEnd: (_) {
            logic.noteInteraction();
            final centerX = logic.posX.value + size / 2;
            final snappedX = centerX < screenSize.width / 2 ? 0.0 : screenSize.width - size;
            logic.savePosition(snappedX, logic.posY.value);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: const Icon(Icons.touch_app, color: Colors.white),
          ),
        ),
      );
    });
  }

  Future<void> _openMenu(AssistiveTouchLogic logic) async {
    final context = Get.context;
    if (context == null) {
      return;
    }
    await Sheet.showBottomSheet(
      context,
      Obx(() {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ...logic.shownBuiltins.map((builtIn) {
                return AssistiveTouchTile.build(
                  icon: builtIn.icon,
                  label: builtIn.labelKey.tr,
                  onTap: () => builtIn == BuiltInAction.deleteVerse ? _confirmDeleteCurrentVerse(logic) : _executeBuiltIn(logic, builtIn),
                );
              }),
              ...logic.actions.map((action) {
                return AssistiveTouchTile.build(
                  icon: Icons.bolt,
                  label: action.name,
                  onTap: () {
                    Get.back();
                    logic.executeAction(action);
                  },
                );
              }),
            ],
          ),
        );
      }),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(I18nKey.assistiveTouch.tr),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.4,
    );
  }

  void _executeBuiltIn(AssistiveTouchLogic logic, BuiltInAction builtIn) {
    Get.back();
    logic.executeBuiltIn(builtIn);
  }

  void _confirmDeleteCurrentVerse(AssistiveTouchLogic logic) {
    MsgBox.yesOrNo(
      title: I18nKey.labelWarning.tr,
      desc: I18nKey.labelDeleteVerse.tr,
      yes: () {
        Get.back(); // 关闭确认弹框
        Get.back(); // 关闭动作菜单
        logic.deleteCurrentVerse();
      },
    );
  }
}
