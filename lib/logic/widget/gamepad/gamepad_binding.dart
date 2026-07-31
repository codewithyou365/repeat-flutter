import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_logic.dart';
import 'package:repeat_flutter/page/repeat/repeat_logic.dart';

/// 底部导航动作。与"闭眼"面板注册的 4 个按钮一致(见 repeat_page.dart 的 doubleUpCallback)：
/// 左 / 中(提示) / 中(提示TTS) / 右。手柄和底部按钮、闭眼面板共用 RepeatLogic 上的同名方法，
/// 手柄本身不新增任何业务逻辑，只是复用已有出口。
enum NavAction { left, middle, middleTts, right }

extension NavActionX on NavAction {
  IconData get icon {
    switch (this) {
      case NavAction.left:
        return Icons.chevron_left;
      case NavAction.middle:
        return Icons.lightbulb_outline;
      case NavAction.middleTts:
        return Icons.record_voice_over;
      case NavAction.right:
        return Icons.chevron_right;
    }
  }

  I18nKey get labelKey {
    switch (this) {
      case NavAction.left:
        return I18nKey.gamepadNavLeft;
      case NavAction.middle:
        return I18nKey.gamepadNavMiddle;
      case NavAction.middleTts:
        return I18nKey.gamepadNavMiddleTts;
      case NavAction.right:
        return I18nKey.gamepadNavRight;
    }
  }
}

/// 一个可被手柄按键触发的功能项，供配置界面列表渲染。
/// descriptor 是持久化用的稳定标识：`nav:<name>` / `builtin:<name>` / `action:<id>`。
class GamepadTarget {
  final String descriptor;
  final IconData icon;
  final String label;

  const GamepadTarget(this.descriptor, this.icon, this.label);
}

/// 手柄"按键 → 功能"绑定的目标定义与分发。
/// 三类可绑定目标：导航(底部三键) / 辅助触控内置动作 / 辅助触控自定义动作。
class GamepadBinding {
  static List<GamepadTarget> navTargets() {
    return NavAction.values.map((a) => GamepadTarget('nav:${a.name}', a.icon, a.labelKey.tr)).toList();
  }

  /// 带号的提示动作文案跟着 book 里定义的提示名字走，条数不够的那几条也不列出来，
  /// 所以要经 AssistiveTouchLogic 取，不能直接读枚举。
  static List<GamepadTarget> builtinTargets(RepeatLogic logic) {
    final assistive = logic.assistiveTouchLogic;
    return BuiltInAction.values
        .where((b) => b.tipIndex == null || b.tipIndex! < logic.state.helper.currTipCount())
        .map((b) => GamepadTarget('builtin:${b.name}', b.icon, assistive.labelOf(b)))
        .toList();
  }

  static List<GamepadTarget> customTargets(RepeatLogic logic) {
    return logic.assistiveTouchLogic.actions //
        .where((a) => a.id != null)
        .map((a) => GamepadTarget('action:${a.id}', Icons.bolt, a.name))
        .toList();
  }

  /// 把一个 descriptor 分发到对应的现成方法(与底部三键/悬浮球/手势/内嵌 Web 游戏共用出口)。
  static void dispatch(RepeatLogic logic, String descriptor) {
    final i = descriptor.indexOf(':');
    if (i < 0) {
      return;
    }
    final prefix = descriptor.substring(0, i);
    final rest = descriptor.substring(i + 1);
    switch (prefix) {
      case 'nav':
        _dispatchNav(logic, rest);
        break;
      case 'builtin':
        final b = _builtInByName(rest);
        if (b != null) {
          logic.assistiveTouchLogic.executeBuiltIn(b);
        }
        break;
      case 'action':
        final id = int.tryParse(rest);
        if (id == null) {
          return;
        }
        // 绑定按课堂持久化，但自定义动作是全局表——切到没有这条动作的课堂(或动作已删除)时找不到，静默忽略。
        final match = logic.assistiveTouchLogic.actions.where((a) => a.id == id);
        if (match.isNotEmpty) {
          logic.assistiveTouchLogic.executeAction(match.first);
        }
        break;
    }
  }

  static void _dispatchNav(RepeatLogic logic, String name) {
    switch (name) {
      case 'left':
        logic.onTapLeft();
        break;
      case 'middle':
        logic.onTapMiddle();
        break;
      case 'middleTts':
        logic.onLongTapMiddle();
        break;
      case 'right':
        logic.onLongTapRight();
        break;
    }
  }

  static BuiltInAction? _builtInByName(String name) {
    for (final b in BuiltInAction.values) {
      if (b.name == name) {
        return b;
      }
    }
    return null;
  }

  /// 手柄按键的可读名称。入参是"按下的逻辑键 id"(LogicalKeyboardKey.keyId)。
  /// 调试期用 Flutter 自带的按键名，release 期退回十六进制键码。
  static String keyLabel(int keyId) {
    final name = LogicalKeyboardKey(keyId).debugName;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Key 0x${keyId.toRadixString(16)}';
  }
}
