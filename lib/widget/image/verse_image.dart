import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/widget/gesture/pinch_viewer.dart';

/// 一节的配图区：单张按原比例铺（高度受 [maxHeight] 封顶），多张横着翻页、底下一排圆点。
/// 点一下进全屏，可以捏合放大、左右翻。
///
/// 这块是放进正文那个 ListView 里的（跟文字一起滚），不占固定高度——三个视图的可视区高度
/// 都是死算出来的，固定塞一块图会把正文挤没。
class VerseImage extends StatefulWidget {
  /// 图片的绝对路径，顺序就是显示顺序。
  final List<String> paths;

  /// 图片区最高占多少。多张时就是实际高度。
  final double maxHeight;

  /// 编辑模式下右上角那个按钮的回调，传 null 就不显示（非编辑模式）。
  /// 参数是当前翻到第几张——菜单里"删掉这张"要知道删哪张。
  final void Function(int index)? onEdit;

  const VerseImage({
    super.key,
    required this.paths,
    required this.maxHeight,
    this.onEdit,
  });

  @override
  State<VerseImage> createState() => _VerseImageState();
}

class _VerseImageState extends State<VerseImage> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paths.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          widget.paths.length == 1 ? _single() : _gallery(),
          if (widget.onEdit != null) _editButton(),
        ],
      ),
    );
  }

  Widget _single() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () => _openFullScreen(0),
          child: _thumb(widget.paths.first),
        ),
      ),
    );
  }

  Widget _gallery() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.maxHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.paths.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () => _openFullScreen(i),
                child: _thumb(widget.paths[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.paths.length, (i) {
            final selected = i == _index;
            return Container(
              width: selected ? 8 : 6,
              height: selected ? 8 : 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.withAlpha(90),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _thumb(String path) {
    // 手机上一张原图动辄几千万像素，不给 cacheWidth 解码完直接把内存打爆。
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (MediaQuery.of(context).size.width * dpr).round();
    return Image.file(
      File(path),
      // 翻页换图时不复用上一张的 Element，否则新图解码完之前会先闪一下旧图。
      key: ValueKey(path),
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stack) => _broken(),
    );
  }

  /// 图没了（文件被删、导入没带上）只给个占位，不弹对话框——配图缺一张不该打断学习。
  Widget _broken() {
    return Container(
      height: widget.maxHeight,
      alignment: Alignment.center,
      color: Colors.grey.withAlpha(20),
      child: Icon(Icons.broken_image_outlined, color: Colors.grey.withAlpha(120), size: 32),
    );
  }

  Widget _editButton() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.black.withAlpha(90),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => widget.onEdit!(_index),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.more_horiz, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(int index) {
    Get.dialog(
      _FullScreenGallery(paths: widget.paths, initialIndex: index),
      barrierColor: Colors.black,
      useSafeArea: false,
    );
  }
}

/// 全屏看图：可捏合缩放、可左右翻，点空白或右上角关掉。
class _FullScreenGallery extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const _FullScreenGallery({required this.paths, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  /// 放大之后要把 PageView 的横划关掉，不然两根手指一动就翻到下一张。
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.paths.length,
            onPageChanged: (i) => setState(() => _index = i),
            // 缩放旋转时不让 PageView 跟着翻页：两根手指的移动会被它当成横划。
            physics: _zoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
            itemBuilder: (context, i) {
              return PinchViewer(
                // 跟右上角的关闭按钮同高，别钻到状态栏底下。
                restorePadding: EdgeInsets.only(left: 8, top: MediaQuery.of(context).padding.top + 8),
                maxScale: 8,
                // 裁掉的话放大后拖到边缘就没了，全屏看图铺满整屏，不裁更顺手。
                clip: false,
                onScaleChanged: (scale) {
                  final zoomed = scale > 1.01;
                  if (zoomed != _zoomed) {
                    setState(() => _zoomed = zoomed);
                  }
                },
                child: Center(
                  child: Image.file(
                    File(widget.paths[i]),
                    key: ValueKey(widget.paths[i]),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey.withAlpha(120),
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
          if (widget.paths.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Text(
                '${_index + 1} / ${widget.paths.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
