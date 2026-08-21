import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

/// 一次手势更新之后的缩放/旋转/位移。
typedef PinchState = ({double scale, double rotation, Offset offset});

/// 把向量先旋转 [rot] 弧度再放大 [sc] 倍。
Offset rotateScale(Offset v, double rot, double sc) {
  final cosR = math.cos(rot);
  final sinR = math.sin(rot);
  return Offset((v.dx * cosR - v.dy * sinR) * sc, (v.dx * sinR + v.dy * cosR) * sc);
}

/// 算一次手势更新后的新状态。
///
/// 抽成纯函数是为了能直接测：锚点这段推导最容易写错，而用模拟手势去测的话，
/// 手势识别器的基线是在"第一根手指开始动"那一刻取的，算出来的期望值对不上。
///
/// 要保证的不变量：手势起点 [startFocal] 底下压着的那个内容点，
/// 整个手势过程中一直待在手指下面。
/// - 起点：startFocal = startOffset + M0·(p - center) + center，M0 = R(r0)·S(s0)
/// - 现在：focal      = offset      + R(dr)·S(ds)·M0·(p - center) + center
///
/// 两式相减，M0·(p - center) 消掉，就得到 offset。
PinchState computePinch({
  required double startScale,
  required double startRotation,
  required Offset startOffset,
  required Offset startFocal,
  required Offset focal,
  required Offset center,
  required double gestureScale,
  required double gestureRotation,
  required double minScale,
  required double maxScale,
}) {
  final scale = (startScale * gestureScale).clamp(minScale, maxScale);
  // 撞到上下限之后手指还在张合，增量得按夹过的结果反算，否则画面会跟着手指漂。
  final deltaScale = startScale == 0 ? 1.0 : scale / startScale;
  final anchor = startFocal - startOffset - center;
  return (
    scale: scale,
    rotation: startRotation + gestureRotation,
    offset: focal - center - rotateScale(anchor, gestureRotation, deltaScale),
  );
}

/// 双指缩放 + 旋转 + 拖动的手势层，图片和视频共用。
///
/// 用不了 InteractiveViewer：那个只有缩放和平移，**没有旋转**。这里自己维护
/// 缩放/旋转/位移三个量，好处是能分别设上下限，也能在一次手势里精确地把
/// "手指按住的那个点"钉在原地（见 [_onUpdate] 的推导）。
///
/// 手势约定：
/// - 两根手指：捏合缩放、转动旋转，同时跟着焦点拖动。
/// - 一根手指：只有放大之后才拖动。没放大时拖不动——不然一划就把画面推跑了，
///   而且这一层通常还盖在别的可点区域上面。
/// - 双击复位。
/// - 只要画面不在原位（缩放/旋转/位移任意一项动过），角上就浮出一个"还原"按钮：
///   转歪了或者拖出画外之后，光靠双击不好发现，得有个看得见的出口。
///
/// [onTap] 传进来是因为这一层会挡住底下 widget 的点击（视频横屏点一下要收放操作栏），
/// 单击照样得能传出去。
class PinchViewer extends StatefulWidget {
  final Widget child;

  /// 最小/最大缩放倍数。
  final double minScale;
  final double maxScale;

  /// 单击回调，用来把点击透传给底下原本的逻辑。
  final VoidCallback? onTap;

  /// 缩放倍数变了就回调一次。外层用它避让自己的手势——比如全屏画廊放大之后
  /// 要把 PageView 的横划关掉，不然两根手指一动就翻到下一张去了。
  final ValueChanged<double>? onScaleChanged;

  /// 变换后内容会超出原来的框，默认裁掉（视频尤其必须裁，不然会糊到下面的正文区）。
  final bool clip;

  /// "还原"按钮贴在哪个角。默认左上：右上角在几个用它的地方都被占了
  /// （全屏看图的关闭按钮、视频编辑态的挡板设置按钮）。
  final Alignment restoreAlignment;

  /// "还原"按钮跟边缘的间距。贴着屏幕顶边用时要把状态栏高度加进来，
  /// 不然按钮会钻到刘海底下。
  final EdgeInsets restorePadding;

  const PinchViewer({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 6.0,
    this.onTap,
    this.onScaleChanged,
    this.clip = true,
    this.restoreAlignment = Alignment.topLeft,
    this.restorePadding = const EdgeInsets.all(8),
  });

  @override
  State<PinchViewer> createState() => PinchViewerState();
}

class PinchViewerState extends State<PinchViewer> {
  double _scale = 1;
  double _rotation = 0;
  Offset _offset = Offset.zero;

  // 一次手势开始时的状态。details.scale/rotation 是相对手势起点的累计量，
  // 所以每次 update 都拿"起点状态 + 累计增量"重算，不做逐帧累加（会飘）。
  double _startScale = 1;
  double _startRotation = 0;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  Size _size = Size.zero;

  /// 复位。外部换了内容（翻到下一节、换了一个视频文件）时调它，
  /// 否则上一条留下的缩放旋转会套到新内容上。
  void reset() {
    if (_scale == 1 && _rotation == 0 && _offset == Offset.zero) {
      return;
    }
    setState(() {
      _scale = 1;
      _rotation = 0;
      _offset = Offset.zero;
    });
    widget.onScaleChanged?.call(_scale);
  }

  Offset get _center => Offset(_size.width / 2, _size.height / 2);

  /// 画面还在不在原位。三项任意一项动过都算——只看缩放的话，
  /// 转歪了或者拖出去了就没有还原的出口了。
  bool get transformed => _scale != 1 || _rotation != 0 || _offset != Offset.zero;

  void _onStart(ScaleStartDetails details) {
    _startScale = _scale;
    _startRotation = _rotation;
    _startOffset = _offset;
    _startFocal = details.localFocalPoint;
  }

  void _onUpdate(ScaleUpdateDetails details) {
    // 没放大时单指不拖：这一层往往盖在可点区域上，一划就跑太容易误触。
    if (details.pointerCount < 2 && _startScale <= widget.minScale) {
      return;
    }
    final next = computePinch(
      startScale: _startScale,
      startRotation: _startRotation,
      startOffset: _startOffset,
      startFocal: _startFocal,
      focal: details.localFocalPoint,
      center: _center,
      gestureScale: details.scale,
      gestureRotation: details.rotation,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
    );
    setState(() {
      _scale = next.scale;
      _rotation = next.rotation;
      _offset = next.offset;
    });
    widget.onScaleChanged?.call(_scale);
  }

  void _onEnd(ScaleEndDetails details) {
    // 缩回原始大小就把位移归零，免得内容被拖到框外看不见了。
    // 旋转保留：把拍歪的视频转正是个有意为之的操作，松手就转回去反而奇怪。
    if (_scale <= widget.minScale && _offset != Offset.zero) {
      setState(() => _offset = Offset.zero);
    }
  }

  Widget _restoreButton() {
    return Padding(
      padding: widget.restorePadding,
      child: Material(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: reset,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restart_alt, size: 14, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  I18nKey.labelRestoreView.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        Widget content = Transform(
          // 绕框中心做旋转缩放，位移是纯平移（跟平移可交换），所以直接写进同一个矩阵。
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
            ..rotateZ(_rotation)
            ..scaleByDouble(_scale, _scale, 1, 1),
          child: widget.child,
        );
        if (widget.clip) {
          content = ClipRect(child: content);
        }
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: widget.onTap,
              onDoubleTap: reset,
              onScaleStart: _onStart,
              onScaleUpdate: _onUpdate,
              onScaleEnd: _onEnd,
              child: content,
            ),
            // 放在 Stack 里而不是 content 里面：按钮不能跟着一起缩放旋转，
            // 也不能被 ClipRect 裁掉。
            if (transformed)
              Positioned.fill(
                child: Align(
                  alignment: widget.restoreAlignment,
                  child: _restoreButton(),
                ),
              ),
          ],
        );
      },
    );
  }
}
