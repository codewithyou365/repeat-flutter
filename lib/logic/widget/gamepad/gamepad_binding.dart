import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
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
/// descriptor 是持久化用的稳定标识：`nav:<name>` / `action:<id>`。
/// 老版本还有一类 `builtin:<枚举名>`——内置动作已经并进悬浮球动作里，这类绑定读到就当没绑。
class GamepadTarget {
  final String descriptor;
  final IconData icon;
  final String label;

  const GamepadTarget(this.descriptor, this.icon, this.label);
}

/// 手柄"按键 → 功能"绑定的目标定义与分发。
/// 两类可绑定目标：导航(底部三键) / 悬浮球动作。
class GamepadBinding {
  static List<GamepadTarget> navTargets() {
    return NavAction.values.map((a) => GamepadTarget('nav:${a.name}', a.icon, a.labelKey.tr)).toList();
  }

  static List<GamepadTarget> customTargets(RepeatLogic logic) {
    return logic.assistiveTouchLogic.actions //
        .map((a) => GamepadTarget('action:${a.id}', a.type.icon, a.name))
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
      case 'action':
        final id = int.tryParse(rest);
        if (id == null) {
          return;
        }
        // 动作已删除(或这条绑定是从别处带过来的)时找不到，静默忽略。
        final match = logic.assistiveTouchLogic.actions.where((a) => a.id == id);
        if (match.isNotEmpty) {
          logic.assistiveTouchLogic.execute(match.first);
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
