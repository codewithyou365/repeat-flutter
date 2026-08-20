import 'dart:io';

import 'package:flutter/foundation.dart';

/// 息屏录音建章功能的平台门禁。
///
/// sherpa_onnx 和 record 六端都有实现，但这一版只在 Android/iOS 上做 QA：
/// 真息屏需要 Android 前台服务 / iOS audio 后台模式，桌面端没有对应概念也没有意义，
/// web 端 sherpa_onnx 跑不了模型文件。不支持的平台上，Add Chapter 的选择框里
/// 直接不出现这一项，AI 设置入口也不显示——而不是让用户点进去再报错。
class AiSupport {
  static bool get available => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 只有 Android 需要 microphone 类型的前台服务才能在真息屏下继续拿到麦克风。
  /// iOS 靠 Info.plist 的 UIBackgroundModes: audio，没有前台服务这个概念。
  static bool get needsForegroundService => !kIsWeb && Platform.isAndroid;
}
