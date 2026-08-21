import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

/// content 数组里的一个网页项。文件由 ContentWebServer 托在回环上，这里只管显示。
///
/// 三件事在这个 widget 里解决，缺一个都用不了：
///
/// 1. **高度**。WebView 在 ListView 里没有内在高度，不给就是 0。[height] 的语义见
///    VerseField.itemHeight：不写按内容自适应，写了就固定。
/// 2. **手势**。3D 场景要拖着转，ListView 要上下滚，两个都想要垂直拖动。默认把手势
///    全留给列表，点一下才交给网页（[_active]），再点右上角还回来。
/// 3. **实例数**。每个 InAppWebView 都是一个完整的浏览器实例，一节里排上四五个
///    直接把内存吃穿。超过 [maxAlive] 的那些先显示占位，点了才真的建。
class VerseWeb extends StatefulWidget {
  /// 完整的 http 地址，形如 `http://127.0.0.1:<port>/<folder>/<name>`。
  final String url;

  /// 见 VerseField.itemHeight：null 自适应，<=1 按 [availableHeight] 的比例，>1 按逻辑像素。
  final double? height;

  /// 正文区的高度。比例是按它算的，不是按屏幕——视频节的正文区被顶部播放器占掉一块，
  /// 按屏幕算会让同一个 0.5 在视频节和纯文本节里差出一大截。
  final double availableHeight;

  const VerseWeb({
    super.key,
    required this.url,
    required this.height,
    required this.availableHeight,
  });

  /// 同时活着的 WebView 上限。
  static const int maxAlive = 3;

  static int _alive = 0;

  @override
  State<VerseWeb> createState() => _VerseWebState();
}

class _VerseWebState extends State<VerseWeb> {
  /// 手势有没有交给网页。false 时列表能正常滚，网页只是一张"活的图"。
  bool _active = false;

  /// 真的建出 InAppWebView 了没有。超过 [VerseWeb.maxAlive] 时先不建。
  bool _created = false;

  /// 自适应模式下从页面量到的高度。量到之前先给一个够放下加载提示的高度。
  double _measured = 120;

  bool _failed = false;

  InAppWebViewController? _controller;

  static final _settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    javaScriptEnabled: true,
    transparentBackground: true,
    // 缩放交给页面自己处理：3D 场景有自己的双指手势，套一层浏览器缩放只会打架。
    supportZoom: false,
    // 内容是能从外部导入的，别让它顺着 file:// 把 App 的私有目录读出来。
    allowFileAccessFromFileURLs: false,
    allowUniversalAccessFromFileURLs: false,
    // 不许自动播放。闭卷回忆阶段答案是藏着的，一个自动出声的网页等于把答案念出来。
    mediaPlaybackRequiresUserGesture: true,
  );

  @override
  void initState() {
    super.initState();
    if (VerseWeb._alive < VerseWeb.maxAlive) {
      VerseWeb._alive++;
      _created = true;
    }
  }

  @override
  void dispose() {
    if (_created) {
      VerseWeb._alive--;
    }
    super.dispose();
  }

  /// 正文区高度。视图还没来得及量出来时给个兜底值——按 0 算会让比例高度变成 0
  /// （整块看不见），也会让 [_measure] 的 clamp 上下界翻转直接抛。
  double get _available => widget.availableHeight > 0 ? widget.availableHeight : 320;

  /// 固定高度返回具体值，自适应返回 null（由 [_measured] 顶着）。
  double? get _fixedHeight {
    final h = widget.height;
    if (h == null || h <= 0) {
      return null;
    }
    // <=1 是比例，>1 是像素。
    return h <= 1 ? _available * h : h;
  }

  double get _height => _fixedHeight ?? _measured;

  Future<void> _measure() async {
    if (_fixedHeight != null || _controller == null) {
      return;
    }
    try {
      final v = await _controller!.evaluateJavascript(source: 'document.body.scrollHeight');
      final h = v is num ? v.toDouble() : double.tryParse('$v');
      if (h == null || h <= 0 || !mounted) {
        return;
      }
      // 页面写坏了能报出一个天文数字，夹一下，别让一项内容顶掉整个列表。
      final capped = h.clamp(60.0, _available * 3);
      if ((capped - _measured).abs() > 1) {
        setState(() => _measured = capped);
      }
    } catch (_) {}
  }

  void _create() {
    if (_created) {
      return;
    }
    VerseWeb._alive++;
    setState(() => _created = true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: _height,
          child: _created ? _web() : _placeholder(),
        ),
      ),
    );
  }

  Widget _web() {
    return Stack(
      children: [
        Positioned.fill(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: _settings,
            // 没激活时一个识别器都不给平台视图，垂直拖动就顺理成章地归 ListView；
            // 激活之后把拖动、缩放全接过来，3D 才转得动。
            gestureRecognizers: _active
                ? <Factory<OneSequenceGestureRecognizer>>{
                    Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                    Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
                    Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                  }
                : const <Factory<OneSequenceGestureRecognizer>>{},
            onWebViewCreated: (c) => _controller = c,
            onLoadStop: (c, url) => _measure(),
            onReceivedError: (c, request, error) {
              debugPrint('[contentWeb] load failed: ${error.description}');
              if (mounted) {
                setState(() => _failed = true);
              }
            },
            onConsoleMessage: (c, msg) => debugPrint('[contentWeb][${msg.messageLevel}] ${msg.message}'),
          ),
        ),
        if (_failed) Positioned.fill(child: _hint(Icons.error_outline, I18nKey.contentWebFailed.tr)),
        // 遮罩只认单击：没有拖动识别器，所以上下拖动照样落到 ListView 上。
        if (!_active && !_failed)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _active = true),
              child: Align(
                alignment: Alignment.bottomRight,
                child: _badge(Icons.touch_app_outlined, I18nKey.contentWebInteract.tr),
              ),
            ),
          ),
        if (_active)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => setState(() => _active = false),
              child: _badge(Icons.close, I18nKey.contentWebExit.tr),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _create,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withAlpha(90)),
        ),
        child: _hint(Icons.public, I18nKey.contentWebLoad.tr),
      ),
    );
  }

  Widget _hint(IconData icon, String text) {
    return Container(
      alignment: Alignment.center,
      color: Colors.grey.withAlpha(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.withAlpha(160)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey.withAlpha(200))),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(110),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
