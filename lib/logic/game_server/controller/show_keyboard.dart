import 'package:repeat_flutter/common/soft_keyboard.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/entity/game_user.dart';

/// 页面加载完、输入框聚焦好之后请求弹软键盘。
/// 只有本机 WebView 里的页面才会发这个请求（局域网进来的其它设备在 web 侧就跳过了），
/// 否则会变成别人进游戏把主机的键盘弹起来。
Future<message.Response?> showKeyboard(message.Request req, GameUser user) async {
  await SoftKeyboard.showForWebView();
  return message.Response();
}
