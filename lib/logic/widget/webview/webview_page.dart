import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'webview_logic.dart';

class WebviewPage {
  static const double _topBarHeight = 50.0;
  static const double _handleHeight = 24.0; // 拉钩区域总高度
  static const double _progressHeight = 4.0;

  static Widget build(WebviewLogic logic, BuildContext context) {
    final state = logic.state;
    final args = state.args;

    if (args == null) {
      return const SizedBox.shrink();
    }

    final Size screenSize = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double screenWidth = screenSize.width;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // 使用 Column，这样 TopBar 展开时会自动挤压下方的 WebView，动态调整 bodyHeight
      body: Column(
        children: [
          // 1. 顶部状态栏安全区
          SizedBox(height: topPadding),

          // 2. 动画顶部栏 (包含高度伸缩 + 渐隐效果)
          Obx(() {
            final isVisible = state.isTopBarVisible.value;
            return ClipRect(
              // 裁剪边缘，防止动画过程中内容超出范围
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: isVisible ? _topBarHeight : 0.0,
                width: screenWidth,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  // 稍微比高度动画快一点点，效果更好
                  opacity: isVisible ? 1.0 : 0.0,
                  // 使用 OverflowBox 防止在高度缩小时内部 Row 报高度溢出错误
                  child: OverflowBox(
                    minHeight: _topBarHeight,
                    maxHeight: _topBarHeight,
                    alignment: Alignment.topCenter,
                    child: _buildTopBarContainer(logic, context, screenWidth, theme),
                  ),
                ),
              ),
            );
          }),

          // 3. 触控拉钩 (始终显示在 TopBar 下方)
          GestureDetector(
            onTap: () => state.isTopBarVisible.value = !state.isTopBarVisible.value,
            behavior: HitTestBehavior.opaque, // 确保整行都可以点击
            child: Container(
              height: _handleHeight,
              width: screenWidth,
              alignment: Alignment.center,
              child: Container(
                width: 40, // 视觉上的小灰条宽度
                height: 5, // 视觉上的小灰条高度
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // 4. 进度条
          Obx(() => _buildProgressBar(logic, context, screenWidth, theme)),

          // 5. WebView 主体
          // 使用 Expanded，当上面的 TopBar 出现/消失时，这里的高度会自动平滑调整
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: (screenWidth > screenSize.height) ? leftPadding : 0,
              ),
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(args.initialUrl)),
                initialSettings: logic.settings,
                onWebViewCreated: (controller) => logic.webViewController = controller,
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
                  debugPrint("WebView Error: ${error.description}");
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 辅助构建方法 ---

  static Widget _buildTopBarContainer(
    WebviewLogic logic,
    BuildContext context,
    double screenWidth,
    ThemeData theme,
  ) {
    return Container(
      height: _topBarHeight,
      width: screenWidth,
      color: theme.scaffoldBackgroundColor,
      child: _topBar(
        logic: logic,
        context: context,
        width: screenWidth,
        height: _topBarHeight,
      ),
    );
  }

  static Widget _buildProgressBar(
    WebviewLogic logic,
    BuildContext context,
    double screenWidth,
    ThemeData theme,
  ) {
    final state = logic.state;
    return Container(
      height: _progressHeight,
      color: theme.scaffoldBackgroundColor,
      child: state.isLoading.value
          ? LinearProgressIndicator(
              value: state.progress.value,
              backgroundColor: theme.dividerColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            )
          : SizedBox(height: _progressHeight, width: screenWidth),
    );
  }

  static Widget _topBar({
    required WebviewLogic logic,
    required BuildContext context,
    required double width,
    required double height,
  }) {
    final state = logic.state;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              logic.state.isTopBarVisible.value = false;
              final onClose = logic.onClose;
              if (onClose != null) onClose();
            },
          ),
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
