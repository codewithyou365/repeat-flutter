import 'package:screen_brightness/screen_brightness.dart';

/// 屏幕调暗/还原。用的是"应用窗口亮度"而不是系统亮度：不改系统设置、
/// Android 不需要 WRITE_SETTINGS、App 退到后台时系统会自己把窗口亮度还原。
///
/// 还原点不止一处（网页关闭闭眼、退出复习页、JS 运行时销毁），所以用 _dimmed
/// 做幂等，没调暗过就不去调用 reset。
/// Linux 没有对应的插件实现，调用会抛 MissingPluginException，这里一律吞掉。
class ScreenBrightnessHelper {
  static bool _dimmed = false;

  static Future<void> dim() async {
    if (_dimmed) {
      return;
    }
    try {
      await ScreenBrightness().setApplicationScreenBrightness(0.0);
      _dimmed = true;
    } catch (e) {
      print("❌ setApplicationScreenBrightness failed: $e");
    }
  }

  static Future<void> restore() async {
    if (!_dimmed) {
      return;
    }
    // 先标记再调用：万一 reset 抛异常，也别让状态卡在"已调暗"，
    // 否则后面的还原全部被幂等判断挡掉，屏幕就一直是暗的。
    _dimmed = false;
    try {
      // 不自己记录原亮度：reset 是还给系统当前值，比写回一个可能已经过时的旧值更稳。
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      print("❌ resetApplicationScreenBrightness failed: $e");
    }
  }
}
