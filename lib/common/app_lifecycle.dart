import 'package:flutter/widgets.dart';

/// 全局的"App 是不是在前台"标志。
///
/// 存在的理由：锁屏/切走之后，内嵌 WebView 里的 JS 会被 Chromium 冻结，2s 心跳发不出来，
/// 而 Node 的 10s 保活扫描不知道这回事，会把本机 WebView 那条连接当成掉线关掉，解锁回来
/// 就是"服务连不上"。所以那条扫描要能查一下当前到底是不是后台（见 lib/common/ws/node.dart）。
///
/// 在 main() 里装一次，全程有效；各页面自己的生命周期需求另行 addObserver，不要依赖这里。
class AppLifecycle with WidgetsBindingObserver {
  static final AppLifecycle _instance = AppLifecycle._();

  AppLifecycle._();

  /// App 是否不在前台（paused/hidden/detached）。默认 false，装 observer 之前一律按前台算。
  static bool background = false;

  /// 回到前台的通知：谁需要在解锁/切回来时自愈，往这里挂回调。
  static final List<VoidCallback> _onResumed = [];

  static void install() {
    WidgetsBinding.instance.addObserver(_instance);
  }

  static void addOnResumed(VoidCallback callback) {
    _onResumed.add(callback);
  }

  static void removeOnResumed(VoidCallback callback) {
    _onResumed.remove(callback);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasBackground = background;
    background = state != AppLifecycleState.resumed;
    if (wasBackground && !background) {
      // 复制一份再遍历：回调里可能会 removeOnResumed
      for (final callback in List<VoidCallback>.from(_onResumed)) {
        callback();
      }
    }
  }
}
