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
