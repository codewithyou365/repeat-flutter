import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'webview_logic.dart';

class WebviewPage {
  static const double _topBarHeight = 50.0;
  static const double _progressHeight = 4.0;
  static const double _handleHeight = 30.0; // 增加了拉钩的触控高度，更容易点

  static Widget build(WebviewLogic logic, BuildContext context) {
    final state = logic.state;
    final args = state.args;

    if (args == null) {
      return const SizedBox.shrink();
    }

    final Size screenSize = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double inset = MediaQuery.of(context).viewInsets.bottom;
    final double screenWidth = screenSize.width;
    final theme = Theme.of(context);

    // 组合 TopBar 和 ProgressBar 的总高度
    final double floatingBarHeight = _topBarHeight + _progressHeight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // 使用 Stack 布局，所有组件像图层一样堆叠
      body: Stack(
        children: [
          // 1. 底层：WebView (铺满剩余空间，一点不浪费)
          Positioned(
            top: topPadding,
            // 从状态栏下方开始
            bottom: inset,
            // 避开键盘
            left: (screenWidth > screenSize.height) ? leftPadding : 0,
            right: 0,
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

          // 2. 遮罩层：防止 TopBar 隐藏时，网页内容透出状态栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding,
            child: Container(color: theme.scaffoldBackgroundColor),
          ),

          // 3. 悬浮 TopBar + ProgressBar (带滑动动画)
          Obx(() {
            final isVisible = state.isTopBarVisible.value;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              // 如果显示，贴着状态栏；如果隐藏，向上缩回屏幕外
              top: isVisible ? topPadding : topPadding - floatingBarHeight,
              left: 0,
              right: 0,
              height: floatingBarHeight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isVisible ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      if (isVisible)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _topBar(
                        logic: logic,
                        context: context,
                        width: screenWidth,
                        height: _topBarHeight,
                      ),
                      _buildProgressBar(logic, context, screenWidth, theme),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 4. 悬浮 & 可拖拽的拉钩
          Obx(() {
            final isVisible = state.isTopBarVisible.value;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              // Y 轴跟随 TopBar：显示时在 TopBar 下方，隐藏时贴着状态栏
              top: isVisible ? topPadding + floatingBarHeight : topPadding,
              left: 0,
              right: 0,
              height: _handleHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 使用我们自定义的局部状态组件，处理 X 轴的独立拖拽
                  _DraggableHandle(
                    screenWidth: screenWidth,
                    onTap: () => state.isTopBarVisible.value = !isVisible,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 辅助构建方法 ---

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

/// 局部的可拖拽拉钩组件
/// 单独提取出来是为了用 StatefulWidget 维护拉钩的 X 轴位置，不污染原有的 Logic/State
class _DraggableHandle extends StatefulWidget {
  final double screenWidth;
  final VoidCallback onTap;

  const _DraggableHandle({required this.screenWidth, required this.onTap});

  @override
  State<_DraggableHandle> createState() => _DraggableHandleState();
}

class _DraggableHandleState extends State<_DraggableHandle> {
  late double _xPos;
  final double _handleWidth = 60.0; // 拉钩触控区域的总宽度

  @override
  void initState() {
    super.initState();
    // 初始居中显示
    _xPos = (widget.screenWidth - _handleWidth) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _xPos,
      top: 0,
      bottom: 0,
      width: _handleWidth,
      child: GestureDetector(
        // 点击切换 TopBar 状态
        onTap: widget.onTap,
        // 水平拖拽更新 X 轴坐标
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            // 限制拖拽范围，防止拉钩飞出屏幕外
            if (_xPos < 0) _xPos = 0;
            if (_xPos > widget.screenWidth - _handleWidth) {
              _xPos = widget.screenWidth - _handleWidth;
            }
          });
        },
        child: Container(
          color: Colors.transparent, // 设置为透明确保能接收触控事件
          alignment: Alignment.center,
          child: Container(
            width: 40, // 视觉上的拉钩宽度
            height: 6, // 视觉上的拉钩厚度
            decoration: BoxDecoration(
              // 半透明背景，带一点阴影，让悬浮感更强
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
