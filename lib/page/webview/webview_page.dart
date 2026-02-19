import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'webview_logic.dart';
import 'webview_args.dart';

class WebviewPage extends StatelessWidget {
  const WebviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<WebviewLogic>();
    final state = logic.state;
    final args = Get.arguments as WebviewArgs;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(state.title.value)),
        actions: [
          Obx(() => IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: state.canGoBack.value ? logic.goBack : null,
          )),
          Obx(() => IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: state.canGoForward.value ? logic.goForward : null,
          )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: logic.reload,
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          Obx(() => state.isLoading.value
              ? LinearProgressIndicator(
            value: state.progress.value,
            backgroundColor: Colors.grey[200],
          )
              : const SizedBox.shrink()),
          // WebView 主体
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(args.initialUrl)),
              initialSettings: logic.settings,
              onWebViewCreated: (controller) {
                logic.webViewController = controller;
              },
              onLoadStart: (controller, url) {
                state.isLoading.value = true;
                state.currentUrl.value = url.toString();
              },
              onLoadStop: (controller, url) async {
                state.isLoading.value = false;
                state.currentUrl.value = url.toString();
                await logic.updateNavigationState();
              },
              onProgressChanged: (controller, progress) {
                state.progress.value = progress / 100;
              },
              onReceivedServerTrustAuthRequest: logic.handleSslChallenge,
              onReceivedError: (controller, request, error) {
                state.isLoading.value = false;
                debugPrint("WebView 错误: ${error.description}");
              },
            ),
          ),
        ],
      ),
    );
  }
}