import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

import 'webview_logic.dart';

class WebviewPage {
  static const double _topBarHeight = 50.0;
  static const double _progressHeight = 4.0;
  static const double _handleHeight = 30.0;

  static Widget build(WebviewLogic logic, BuildContext context) {
    final state = logic.state;
    final args = state.args;

    if (args == null) return const SizedBox.shrink();

    final Size screenSize = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double inset = MediaQuery.of(context).viewInsets.bottom;
    final double screenWidth = screenSize.width;
    final theme = Theme.of(context);
    final double floatingBarHeight = _topBarHeight + _progressHeight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. WebView 层
          Positioned(
            top: topPadding,
            bottom: inset,
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
              onProgressChanged: (controller, progress) => state.progress.value = progress / 100,
              onReceivedServerTrustAuthRequest: logic.handleSslChallenge,
              onReceivedError: (controller, request, error) {
                state.isLoading.value = false;
                debugPrint("WebView Error: ${error.description}");
              },
            ),
          ),

          // 2. 状态栏遮罩
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding,
            child: Container(color: theme.scaffoldBackgroundColor),
          ),

          // 3. 悬浮 TopBar
          Obx(() {
            final isVisible = state.isTopBarVisible.value;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
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
                          color: Colors.black.withValues(alpha: 0.1),
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

          // 4. 悬浮拉钩 (Handle)
          Obx(() {
            final isVisible = state.isTopBarVisible.value;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isVisible ? topPadding + floatingBarHeight : topPadding,
              left: 0,
              right: 0,
              height: _handleHeight,
              child: _DraggableHandle(
                screenWidth: screenWidth,
                onTap: () => state.isTopBarVisible.value = !isVisible,
              ),
            );
          }),
        ],
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
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: logic.reload),
        ],
      ),
    );
  }
}

class _DraggableHandle extends StatefulWidget {
  final double screenWidth;
  final VoidCallback onTap;

  const _DraggableHandle({required this.screenWidth, required this.onTap});

  @override
  State<_DraggableHandle> createState() => _DraggableHandleState();
}

class _DraggableHandleState extends State<_DraggableHandle> {
  double? _xPos;
  final double _handleWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  /// 从数据库加载位置
  Future<void> _loadPosition() async {
    try {
      String? savedPos = await Db().db.kvDao.getStr(K.webviewHandlePos);

      if (savedPos != null) {
        double parsed = double.tryParse(savedPos) ?? 0;
        // 简单校验，防止屏幕旋转或变更后位置越界
        if (parsed > widget.screenWidth - _handleWidth) {
          parsed = widget.screenWidth - _handleWidth;
        }
        setState(() => _xPos = parsed);
      } else {
        // 没存过则居中
        setState(() => _xPos = (widget.screenWidth - _handleWidth) / 2);
      }
    } catch (e) {
      setState(() => _xPos = (widget.screenWidth - _handleWidth) / 2);
    }
  }

  /// 保存位置到数据库
  Future<void> _savePosition() async {
    if (_xPos == null) return;
    try {
      await Db().db.kvDao.insertOrReplace(Kv(K.webviewHandlePos, _xPos.toString()));
    } catch (e) {
      debugPrint("Save position failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_xPos == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned(
          left: _xPos,
          top: 0,
          bottom: 0,
          width: _handleWidth,
          child: GestureDetector(
            onTap: widget.onTap,
            onPanUpdate: (details) {
              setState(() {
                _xPos = (_xPos! + details.delta.dx).clamp(0.0, widget.screenWidth - _handleWidth);
              });
            },
            onPanEnd: (_) => _savePosition(),
            child: Container(
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2, offset: const Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
