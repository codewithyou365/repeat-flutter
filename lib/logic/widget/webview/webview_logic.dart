import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'webview_page.dart';
import 'webview_args.dart';
import 'webview_state.dart';

class WebviewLogic {
  final WebviewState state = WebviewState();
  InAppWebViewController? webViewController;
  VoidCallback? onClose;
  final InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllowFullscreen: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    transparentBackground: true,
  );

  // 临时排查用：网页白屏时分不清是"JS 抛异常"还是"JS 主线程卡死"。
  // 这里在文档最开始注入错误捕获 + 2 秒心跳，全部走 console 转发到 I/flutter：
  // 心跳停了 = 卡死（死循环），心跳还在但有 [jsErr]/[jsRej] = 抛异常。排查完可整块删掉。
  final UnmodifiableListView<UserScript> debugUserScripts = UnmodifiableListView([
    UserScript(
      source: '''
window.addEventListener('error', function (e) {
  console.log('[jsErr] ' + e.message + ' @ ' + e.filename + ':' + e.lineno);
});
window.addEventListener('unhandledrejection', function (e) {
  var r = e.reason;
  console.log('[jsRej] ' + ((r && r.stack) || String(r)));
});
var __beat = 0;
setInterval(function () {
  __beat++;
  console.log('[alive] ' + __beat + ' bodyLen=' + (document.body ? document.body.innerHTML.length : -1));
}, 2000);
''',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
  ]);

  Widget build(WebviewArgs args, VoidCallback onClose, BuildContext context) {
    this.onClose = onClose;
    state.args = args;
    state.title.value = args.pageTitle;
    return WebviewPage.build(this, context);
  }

  Future<ServerTrustAuthResponse?> handleSslChallenge(InAppWebViewController controller, URLAuthenticationChallenge challenge) async {
    var args = state.args;
    if (args == null) {
      return null;
    }
    if (args.selfCertificate) {
      return ServerTrustAuthResponse(
        action: ServerTrustAuthResponseAction.PROCEED,
      );
    }

    return null;
  }

  // 更新导航状态
  Future<void> updateNavigationState() async {
    if (webViewController == null) return;
    state.canGoBack.value = await webViewController!.canGoBack();
    state.canGoForward.value = await webViewController!.canGoForward();
  }

  // --- 控制方法 ---

  void goBack() async {
    if (await webViewController?.canGoBack() ?? false) {
      await webViewController?.goBack();
    }
  }

  void goForward() async {
    if (await webViewController?.canGoForward() ?? false) {
      await webViewController?.goForward();
    }
  }

  void reload() async {
    await webViewController?.reload();
  }
}
