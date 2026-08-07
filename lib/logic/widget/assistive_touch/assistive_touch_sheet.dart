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
              child: LayoutBuilder(builder: (context, constraints) {
                final tileWidth = AssistiveTouchTile.widthFor(constraints.maxWidth);
                return Wrap(
                  spacing: AssistiveTouchTile.spacing,
                  runSpacing: AssistiveTouchTile.spacing,
                  children: [
                    ...logic.shownBuiltins.map((builtIn) {
                      return AssistiveTouchTile.build(
                        icon: builtIn.icon,
                        label: logic.labelOf(builtIn),
                        width: tileWidth,
                        onTap: () => _showBuiltInMenu(logic, builtIn),
                      );
                    }),
                    ...logic.actions.map((action) {
                      return AssistiveTouchTile.build(
                        icon: Icons.bolt,
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
                      onTap: () => _showAddSelector(logic),
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

  /// 点内置动作的格子弹目录：TTS-*/后退 有"编辑"（重新调参数），其它内置动作（播放/删除当前节等）
  /// 没有可调的参数，目录里只有"删除"。
  static Future<void> _showBuiltInMenu(AssistiveTouchLogic logic, BuiltInAction builtIn) async {
    final editable = builtIn.qaType != null || builtIn.isSeekBack;
    await _showMenu(
      title: logic.labelOf(builtIn),
      editable: editable,
      onEdit: () => _editBuiltIn(logic, builtIn),
      onDelete: () => _confirmRemoveBuiltIn(logic, builtIn),
    );
  }

  /// 自定义动作本来就是表单配出来的，目录里"编辑"始终可选。
  static Future<void> _showActionMenu(AssistiveTouchLogic logic, AssistiveTouchAction action) async {
    await _showMenu(
      title: action.name,
      editable: true,
      onEdit: () => _editAction(logic, action),
      onDelete: () => _confirmDelete(logic, action),
    );
  }

  static Future<void> _showMenu({
    required String title,
    required bool editable,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) async {
    await Sheet.showBottomSheet(
      Get.context!,
      ListView(
        shrinkWrap: true,
        children: [
          if (editable)
            RowWidget.buildSelect(
              title: I18nKey.labelEdit.tr,
              leading: const Icon(Icons.edit),
              onTap: () {
                Get.back();
                onEdit();
              },
            ),
          RowWidget.buildSelect(
            title: I18nKey.labelDelete.tr,
            leading: const Icon(Icons.delete),
            onTap: () {
              Get.back();
              onDelete();
            },
          ),
        ],
      ),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(title),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.3,
    );
  }

  /// TTS-* 重新弹"TTS设置"调参数；"后退"重新弹秒数选择器——跟新增时用的是同一个 sheet，
  /// 里面点确定会再 setBuiltInVisible(true)一次，反正已经是 true，不会有副作用。
  static Future<void> _editBuiltIn(AssistiveTouchLogic logic, BuiltInAction builtIn) async {
    if (builtIn.isSeekBack) {
      await _askSeekBackSecondsThenAdd(logic, builtIn);
      return;
    }
    final qaType = builtIn.qaType;
    if (qaType != null) {
      await logic.repeatLogic.ttsHelper.open(qaType.ttsKeys);
    }
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
                crossAxisCount: AssistiveTouchTile.columns,
                // 一行少放一个，格子就变宽了，高度按老比例算会空一大截，同步调平。
                childAspectRatio: 1.2,
                children: addable.map((builtIn) {
                  return AssistiveTouchTile.build(
                    icon: builtIn.icon,
                    label: logic.labelOf(builtIn),
                    width: double.infinity,
                    onTap: () {
                      Get.back();
                      if (builtIn.isSeekBack && !AssistiveTouchLogic.tipGateways.contains(builtIn)) {
                        _askSeekBackSecondsThenAdd(logic, builtIn);
                      } else if (AssistiveTouchLogic.tipGateways.contains(builtIn)) {
                        // TTS-Tips / Play-Tips 是入口，先选作用在第几条提示上。
                        _askTipThenAdd(logic, builtIn);
                      } else if (builtIn.qaType != null) {
                        _askTtsThenAdd(logic, builtIn);
                      } else {
                        logic.setBuiltInVisible(builtIn, true);
                      }
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

  /// "后退"的秒数只在勾选它时问一次，问完直接落库并把它加进菜单——比常驻在设置里占位置、
  /// 又要多一次"改了要不要生效"的心智负担更省事。
  /// 秒数是整族"后退-*"共用的一份，在哪个上面改都一样。
  static Future<void> _askSeekBackSecondsThenAdd(AssistiveTouchLogic logic, BuiltInAction builtIn) async {
    final selected = _seekBackIndex(logic.seekBackSeconds.value).obs;
    await Sheet.showBottomSheet(
      Get.context!,
      ListView(
        shrinkWrap: true,
        children: [
          RowWidget.buildCupertinoPicker(
            title: I18nKey.seekBackSeconds.tr,
            options: seekBackOptions.map((e) => '$e').toList(),
            value: selected.value,
            changed: (index) => selected.value = index,
          ),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildButtons([
            Button(I18nKey.btnOk.tr, () async {
              await logic.setSeekBackSeconds(seekBackOptions[selected.value]);
              await logic.setBuiltInVisible(builtIn, true);
              Get.back();
            }),
          ]),
        ],
      ),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(logic.labelOf(builtIn)),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.4,
    );
  }

  /// 一节可以挂好几条提示，所以 TTS-Tips / Play-Tips 不直接加进菜单，先问作用在第几条上。
  /// 已经加过的那几条不再列出来，选完 TTS 的还要照常走一遍"TTS设置"。
  static Future<void> _askTipThenAdd(AssistiveTouchLogic logic, BuiltInAction gateway) async {
    final candidates = logic.tipActionsOf(gateway).where((e) => !logic.visibleBuiltins.contains(e)).toList();
    if (candidates.isEmpty) {
      return;
    }
    await Sheet.showBottomSheet(
      Get.context!,
      ListView(
        shrinkWrap: true,
        children: candidates.map((action) {
          return RowWidget.buildSelect(
            title: logic.tipLabel(action.tipIndex!),
            leading: Icon(gateway.icon),
            onTap: () {
              Get.back();
              if (action.qaType != null) {
                _askTtsThenAdd(logic, action);
              } else if (action.isSeekBack) {
                _askSeekBackSecondsThenAdd(logic, action);
              } else {
                logic.setBuiltInVisible(action, true);
              }
            },
          );
        }).toList(),
      ),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(gateway.labelKey.tr),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.5,
    );
  }

  /// TTS-* 动作勾选时先弹现成的"TTS设置"sheet 让用户把语速/音色调好，
  /// 关掉那个 sheet 后才落库把动作加进菜单——跟"后退"秒数一样，只在新增这一下问，
  /// 免得常驻在设置里占地方。
  static Future<void> _askTtsThenAdd(AssistiveTouchLogic logic, BuiltInAction builtIn) async {
    final qaType = builtIn.qaType;
    if (qaType == null) {
      await logic.setBuiltInVisible(builtIn, true);
      return;
    }
    final confirmed = await logic.repeatLogic.ttsHelper.open(qaType.ttsKeys);
    if (!confirmed) {
      return;
    }
    await logic.setBuiltInVisible(builtIn, true);
  }
}
