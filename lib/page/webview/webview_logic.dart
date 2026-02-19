import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'webview_args.dart';
import 'webview_state.dart';

class WebviewLogic extends GetxController {
  final WebviewState state = WebviewState();
  InAppWebViewController? webViewController;

  final InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllowFullscreen: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
  );

  @override
  void onInit() {
    super.onInit();
    var args = Get.arguments as WebviewArgs;
    state.title.value = args.pageTitle;
  }

  Future<ServerTrustAuthResponse?> handleSslChallenge(
      InAppWebViewController controller, URLAuthenticationChallenge challenge) async {
    var args = Get.arguments as WebviewArgs;

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