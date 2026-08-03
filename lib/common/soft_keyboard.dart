import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
    try {
      final shown = await _channel.invokeMethod<bool>('showSoftInputForWebView');
      return shown ?? false;
    } catch (e) {
      debugPrint('SoftKeyboard.showForWebView failed: $e');
      return false;
    }
  }
}
