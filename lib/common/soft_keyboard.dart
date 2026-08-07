import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 唤起系统软键盘。
///
/// 内嵌 WebView 里的页面自己调 input.focus() 是弹不出键盘的：Chromium 只在页面有用户手势
/// 时才因聚焦唤起 IME，而"进入游戏"那一下点击发生在 Flutter 这边。所以由页面通过
/// /api/showKeyboard 请求过来，最终落到原生的 InputMethodManager。
class SoftKeyboard {
  static const MethodChannel _channel = MethodChannel('repeat_flutter/keyboard');

  /// 只有 Android 实现了，其它平台静默 no-op（iOS 的 keyboardDisplayRequiresUserAction
  /// 是 WKWebView 私有 API，flutter_inappwebview 没暴露）。
  static Future<bool> showForWebView() async {
    if (!Platform.isAndroid) {
      return false;
    }
    // 先把 Flutter 这边的输入焦点和输入法客户端彻底断开，再去给 WebView 抢焦点。
    // Flutter 的 KeyboardManager 会把硬件（蓝牙）键盘的按键优先喂给 TextInputPlugin 最后一次
    // 创建的 InputConnection：只要之前在 Flutter 页面聚焦过任意输入框（比如"改课堂名"），
    // 这个 InputConnection 就一直在，按键会被 Flutter 吃掉，作为子 View 的 WebView 一个都收不到，
    // 表现就是"游戏里蓝牙键盘敲不进字"。软键盘那条路不受影响，所以只有接硬件键盘时才暴露。
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod('TextInput.clearClient');
    } catch (e) {
      debugPrint('SoftKeyboard.clearTextInputClient failed: $e');
    }
    try {
      final shown = await _channel.invokeMethod<bool>('showSoftInputForWebView');
      return shown ?? false;
    } catch (e) {
      debugPrint('SoftKeyboard.showForWebView failed: $e');
      return false;
    }
  }
}
