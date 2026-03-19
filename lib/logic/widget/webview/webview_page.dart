import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_state.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'webview_logic.dart';

class WebviewPage {
  static Widget build(WebviewLogic logic, BuildContext context) {
    final state = logic.state;
    final args = state.args;

    if (args == null) {
      return SizedBox.shrink();
    }
    final Size screenSize = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double inset = MediaQuery.of(context).viewInsets.bottom;
    final double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    var landscape = false;
    if (screenWidth > screenHeight) {
      landscape = true;
    }
    double topBarHeight = 50;
    const double progressHeight = 4.0;
    double bodyHeight = screenHeight - inset - topPadding - topBarHeight - RowWidget.dividerHeight - progressHeight;
    double bodyWidth = screenWidth;
    if (landscape) {
      bodyWidth = screenWidth - leftPadding * 2;
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(height: topPadding),
        topBar(
          logic: logic,
          context: context,
          width: screenWidth,
          height: topBarHeight,
        ),
        Obx(
          () => Container(
            height: progressHeight,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: state.isLoading.value
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: theme.dividerColor,
                        width: 0.5,
                      ),
                    ),
            ),
            child: state.isLoading.value
                ? LinearProgressIndicator(
                    value: state.progress.value,
                    backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  )
                : SizedBox(height: progressHeight, width: screenWidth),
          ),
        ),
        // WebView 主体
        SizedBox(
          height: bodyHeight,
          width: bodyWidth,
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
    );
    //   appBar: AppBar(
    //     title: Obx(() => Text(state.title.value)),
    //     actions: [
    //       Obx(
    //         () => IconButton(
    //           icon: const Icon(Icons.arrow_back_ios),
    //           onPressed: state.canGoBack.value ? logic.goBack : null,
    //         ),
    //       ),
    //       Obx(
    //         () => IconButton(
    //           icon: const Icon(Icons.arrow_forward_ios),
    //           onPressed: state.canGoForward.value ? logic.goForward : null,
    //         ),
    //       ),
    //       IconButton(
    //         icon: const Icon(Icons.refresh),
    //         onPressed: logic.reload,
    //       ),
    //     ],
    //   ),
    //   body: Column(
    //     children: [
    //       // 进度条
    //       Obx(
    //         () => state.isLoading.value
    //             ? LinearProgressIndicator(
    //                 value: state.progress.value,
    //                 backgroundColor: Colors.grey[200],
    //               )
    //             : const SizedBox.shrink(),
    //       ),
    //       // WebView 主体
    //       Expanded(
    //         child: InAppWebView(
    //           initialUrlRequest: URLRequest(url: WebUri(args.initialUrl)),
    //           initialSettings: logic.settings,
    //           onWebViewCreated: (controller) {
    //             logic.webViewController = controller;
    //           },
    //           onLoadStart: (controller, url) {
    //             state.isLoading.value = true;
    //             state.currentUrl.value = url.toString();
    //           },
    //           onLoadStop: (controller, url) async {
    //             state.isLoading.value = false;
    //             state.currentUrl.value = url.toString();
    //             await logic.updateNavigationState();
    //           },
    //           onProgressChanged: (controller, progress) {
    //             state.progress.value = progress / 100;
    //           },
    //           onReceivedServerTrustAuthRequest: logic.handleSslChallenge,
    //           onReceivedError: (controller, request, error) {
    //             state.isLoading.value = false;
    //             debugPrint("WebView 错误: ${error.description}");
    //           },
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  static Widget topBar({
    required WebviewLogic logic,
    required BuildContext context,
    required double width,
    required double height,
  }) {
    final state = logic.state;
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: logic.onClose,
          ),
          // Title
          Expanded(
            flex: 3,
            child: Obx(
              () => Text(
                state.title.value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(),
          Obx(
            () => IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: state.canGoBack.value ? logic.goBack : null,
            ),
          ),
          Obx(
            () => IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              onPressed: state.canGoForward.value ? logic.goForward : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: logic.reload,
          ),
        ],
      ),
    );
  }
}
