// 有意使用已废弃的 RawKeyboard：新的 HardwareKeyboard 会严格校验按键 down/up 状态，
// 遇到 down/up 逻辑键不一致的手柄会在 debug 下抛断言并中断派发，导致按键失灵。详见 attach()。
// ignore_for_file: deprecated_member_use
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/logic/widget/gamepad/gamepad_binding.dart';
import 'package:repeat_flutter/page/repeat/repeat_logic.dart';

/// 游戏手柄按键 → 功能的绑定与输入分发。仿照 AssistiveTouchLogic，由 RepeatLogic 直接持有一份，
/// 依附于复习会话：只在复习页存活期间监听按键(这些功能本就只在复习页有意义)。
class GamepadLogic {
  final RepeatLogic repeatLogic;

  GamepadLogic(this.repeatLogic);

  // 总开关：跟辅助触控一样按课堂存 CrKv。关闭时不触发任何绑定(但配置弹窗里仍可改键)。
  final enabled = false.obs;

  // "按下时的逻辑键"(LogicalKeyboardKey.keyId) -> target descriptor。
  // 键的选择实测很讲究(某蓝牙手柄):
  //   - 物理键(usbHidUsage)同一会话内 down/up 稳定，但跨会话/重连蓝牙后会变(0x20000031e -> 0x5ff1d)；
  //   - 逻辑键 up 与 down 不一致(down=0x20000031e、up 时而 0x20)，但"按下的逻辑键"跨会话稳定。
  // 所以用"按下的逻辑键"做绑定标识(跨会话稳)，另用物理键做 down/up 配对来防自动连发(见 _pressedPhys)。
  // 约定 键<->功能 一一对应：一个按键最多绑一个功能，一个功能最多被一个按键绑定。
  final RxMap<int, String> bindings = <int, String>{}.obs;

  // 记录当前按住的物理键(usbHidUsage)，用于过滤长按时系统重复上报的 RawKeyDownEvent，避免连发。
  final _pressedPhys = <int>{};

  bool _attached = false;
  // 配置界面"按键捕获"进行中时挂上：下一次按键不执行功能，而是回传其逻辑键 id 用于绑定。
  ValueChanged<int>? _captureCallback;

  // 手柄绑定跟辅助触控一样按课堂走(不同课堂可有不同映射)，存到按 classroomId 分开的 CrKv 的一条 JSON。
  Future<void> loadSettings() async {
    enabled.value = (await Db().db.crKvDao.getInt(Classroom.curr, CrK.gamepadEnabled)) == 1;
    bindings.clear();
    final raw = await Db().db.crKvDao.getStr(Classroom.curr, CrK.gamepadBindings);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          final keyId = int.tryParse('$k');
          if (keyId != null && v is String) {
            bindings[keyId] = v;
          }
        });
      }
    } catch (_) {
      // 脏数据直接当作没有绑定，不影响复习。
    }
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.gamepadEnabled, value ? '1' : '0'));
  }

  Future<void> _save() async {
    final map = bindings.map((k, v) => MapEntry(k.toString(), v));
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.gamepadBindings, jsonEncode(map)));
  }

  // 用旧的 RawKeyboard 而不是新的 HardwareKeyboard：后者会严格校验 down/up 的 logicalKey 配对，
  // 遇到上面那种 down/up 逻辑键不一致的手柄，会在 debug 下抛断言并在派发前就中断，导致按键彻底失灵
  // (且重连蓝牙无用，只能重启 app)。RawKeyboard 不做该校验，是手柄输入的稳妥通道。
  void attach() {
    if (_attached) {
      return;
    }
    RawKeyboard.instance.addListener(_onRawKey);
    _attached = true;
  }

  void detach() {
    if (!_attached) {
      return;
    }
    RawKeyboard.instance.removeListener(_onRawKey);
    _attached = false;
    _captureCallback = null;
    _pressedPhys.clear();
  }

  void beginCapture(ValueChanged<int> onCaptured) {
    _captureCallback = onCaptured;
  }

  void cancelCapture() {
    _captureCallback = null;
  }

  /// 抬起时清掉按住记录；按下时只在"从未按住 -> 按下"这一刻触发一次(用物理键配对，过滤长按连发)。
  /// 绑定标识用"按下的逻辑键"(见 bindings 注释)。
  void _onRawKey(RawKeyEvent e) {
    final phys = e.physicalKey.usbHidUsage;
    if (e is RawKeyUpEvent) {
      _pressedPhys.remove(phys);
      return;
    }
    if (e is! RawKeyDownEvent) {
      return;
    }
    if (_pressedPhys.contains(phys)) {
      // 长按时系统会重复上报 RawKeyDownEvent，这里只认第一次。
      return;
    }
    _pressedPhys.add(phys);

    final code = e.logicalKey.keyId;
    final cb = _captureCallback;
    if (cb != null) {
      // 配置弹窗改键时不受总开关影响，方便先配好再开启。
      _captureCallback = null;
      cb(code);
      return;
    }
    if (!enabled.value) {
      return;
    }
    final descriptor = bindings[code];
    if (descriptor == null) {
      return;
    }
    GamepadBinding.dispatch(repeatLogic, descriptor);
  }

  Future<void> bind(int keyId, String descriptor) async {
    // 先解除该功能原来绑的键、以及该键原来绑的功能，保证 键<->功能 一一对应。
    bindings.removeWhere((k, v) => v == descriptor);
    bindings[keyId] = descriptor;
    bindings.refresh();
    await _save();
  }

  Future<void> clear(String descriptor) async {
    bindings.removeWhere((k, v) => v == descriptor);
    bindings.refresh();
    await _save();
  }
}
