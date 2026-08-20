import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

/// 游戏服务器开着时把进程钉在前台（Android 前台服务 + 一条常驻通知）。
///
/// 为什么需要：游戏的 HttpServer/WebSocket、音频判停定时器全跑在 Flutter 主 isolate 上。
/// 手机一锁屏，Android 12+ 的 cached-app freezer 会冻住整个后台进程，局域网上的学生端就
/// 连不上了，音频也不会停在 qEnd。前台服务是唯一可靠的免冻手段。
///
/// 只有 Android 实现，其它平台静默 no-op（桌面端本来就不会被冻结）。
/// 原生实现见 android/app/src/main/kotlin/.../GameForegroundService.kt。
/// 前台服务的种类。原生侧按这个名字选 Service 组件，见 MainActivity.serviceClassOf。
///
/// 必须是两个独立的 Service：Service 是单例组件，合成一个的话，游戏和录音同时开着时
/// 一次 stop 会把另一个也停掉；而且前台服务类型是按组件声明的，合并会让游戏那条路径
/// 也一起受 Android 14 对麦克风前台服务的前置条件约束。
enum ForegroundKind {
  /// 游戏服务器，dataSync 类型
  game,

  /// 息屏录音会话，microphone 类型
  record,
}

class ForegroundService {
  static const MethodChannel _channel = MethodChannel('repeat_flutter/foreground');

  /// [kind] 缺省是 game，所以原有调用点一行都不用改。
  ///
  /// **录音场景的调用顺序有硬要求**：先 `Permission.microphone` 拿到授权，再调这里
  /// （而且必须在页面还可见的时候调），最后才 `record.startStream`。
  /// Android 11+ 的 while-in-use 规则会把后台启动的麦克风前台服务静默静音——
  /// 不抛异常，只是从此录到的全是零，这个 bug 极难查。
  static Future<void> start({ForegroundKind kind = ForegroundKind.game}) async {
    if (!Platform.isAndroid) {
      return;
    }
    // Android 13+ 通知是运行时权限。没授权前台服务照样启得起来、照样免冻，只是通知不显示，
    // 所以这里只顺手问一次，拿不到也不影响后面 start。
    try {
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('ForegroundService.requestNotification failed: $e');
    }
    await _ensureIgnoreBatteryOptimizations();
    try {
      await _channel.invokeMethod<bool>('start', {'kind': kind.name});
    } catch (e) {
      debugPrint('ForegroundService.start failed: $e');
    }
  }

  /// 申请忽略电池优化。
  ///
  /// 为什么需要：前台服务只挡得住 AOSP 那层 cached-app freezer。厂商 ROM（实测小米 MIUI 的
  /// SmartPower）不认 dataSync 前台服务，息屏 3 秒就把进程打成 idle 并限流网络/定时器，
  /// 游戏服务照样停。系统的电池优化白名单是唯一能用代码申请的那一层。
  ///
  /// 系统那个弹窗只说"是否允许后台运行"，用户看不出跟游戏有什么关系，所以先自己弹一个
  /// 说明框讲清原因，用户点了"去设置"才唤起系统弹窗；拒绝或跳过都不影响前台服务照常启动。
  static Future<void> _ensureIgnoreBatteryOptimizations() async {
    try {
      if (await Permission.ignoreBatteryOptimizations.isGranted) {
        return;
      }
      // 没有 context 时 MsgBox 会静默不弹，yes/no 都不会触发，completer 就永远不完成，
      // 把 GameWebServer.start() 一起吊死。这种情况直接跳过，下次开服务再问。
      if (Get.context == null) {
        return;
      }
      final completer = Completer<bool>();
      MsgBox.yesOrNo(
        title: I18nKey.batteryOptTitle.tr,
        desc: I18nKey.batteryOptDesc.tr,
        yesBtnTitle: I18nKey.batteryOptGoSet.tr,
        yes: () {
          Get.back();
          completer.complete(true);
        },
        no: () {
          Get.back();
          completer.complete(false);
        },
      );
      if (!await completer.future) {
        return;
      }
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e) {
      debugPrint('ForegroundService.requestIgnoreBatteryOptimizations failed: $e');
    }
  }

  static Future<void> stop({ForegroundKind kind = ForegroundKind.game}) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('stop', {'kind': kind.name});
    } catch (e) {
      debugPrint('ForegroundService.stop failed: $e');
    }
  }
}
