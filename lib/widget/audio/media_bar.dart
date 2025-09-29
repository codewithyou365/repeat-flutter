import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

typedef MediaDurationMsCallback = int Function();
typedef MediaPlayCallback = Future<void> Function(Duration position);
typedef MediaStopCallback = Future<void> Function();
typedef MediaEditCallback = Future<void> Function(int ms);
typedef MediaAdjustSpeedCallback = Future<void> Function(double speed);
typedef MediaGetSpeedCallback = double Function();

class MediaBar extends StatefulWidget {
  static const double pixelPerMs = 0.06;

  final double width;
  final double height;
  final int verseStartMs;
  final int verseEndMs;
  final MediaDurationMsCallback duration;
  final MediaPlayCallback onPlay;
  final MediaStopCallback onStop;
  final MediaEditCallback? onEdit;
  final MediaAdjustSpeedCallback? onAdjustSpeed;
  final MediaGetSpeedCallback? getSpeed;
  final bool hideTime;

  const MediaBar({
    required this.width,
    required this.height,
    required this.verseStartMs,
    required this.verseEndMs,
    required this.duration,
    required this.onPlay,
    required this.onStop,
    required this.onEdit,
    required this.onAdjustSpeed,
    required this.getSpeed,
    required this.hideTime,
    Key? key,
  }) : super(key: key);

  @override
  MediaBarState createState() => MediaBarState();
}

class MediaBarState extends State<MediaBar> with SingleTickerProviderStateMixin {
  int _startMillisecondsSinceEpoch = 0;
  int _startMediaPositionMs = 0;
  double _blockOffset = 0.0;
  double _previousDragOffset = 0.0;
  bool _isPlaying = false;
  double _currentSpeed = 1.0;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animController.addListener(_updateOffset);

    if (widget.getSpeed != null) {
      _currentSpeed = widget.getSpeed!();
    }
  }

  void _updateOffset() {
    if (!mounted || !_isPlaying) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final double elapsedMs = _startMediaPositionMs + (nowMs - _startMillisecondsSinceEpoch) * _currentSpeed;
    if (_startMediaPositionMs + 50 >= widget.verseEndMs) {
      if (elapsedMs >= widget.duration()) {
        _stopPlayback();
        return;
      }
    } else if (elapsedMs >= widget.verseEndMs) {
      _stopPlayback();
      return;
    }
    final newOffset = -(elapsedMs - widget.verseStartMs) * MediaBar.pixelPerMs;
    if (_blockOffset != newOffset) {
      setState(() {
        _blockOffset = newOffset;
      });
    }
  }

  Future<void> _stopPlayback() async {
    if (!_isPlaying) return;

    await widget.onStop();
    _animController.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> stop() async {
    await _stopPlayback();
  }

  void playFromStart() {
    _playAtPosition(timeOffsetMs: widget.verseStartMs);
  }

  Future<void> _playAtPosition({int? timeOffsetMs, int? incrementMs}) async {
    int currPositionMs;

    if (timeOffsetMs != null) {
      currPositionMs = timeOffsetMs;
    } else if (incrementMs != null) {
      final currentPositionMs = widget.verseStartMs + (-_blockOffset / MediaBar.pixelPerMs).floor();
      currPositionMs = currentPositionMs + incrementMs;
      if (currPositionMs < 0) {
        currPositionMs = 0;
      } else {
        int durationMs = widget.duration();
        if (durationMs == 0) {
          durationMs = widget.verseEndMs;
        }
        if (currPositionMs > durationMs) {
          currPositionMs = durationMs;
        }
      }
    } else {
      currPositionMs = widget.verseStartMs + (-_blockOffset / MediaBar.pixelPerMs).floor();
    }

    var durationMs = widget.verseEndMs - currPositionMs;

    if (durationMs <= 50) {
      durationMs = widget.duration() - currPositionMs;
    }

    if (durationMs <= 50) {
      durationMs = 200;
      currPositionMs = widget.duration() - durationMs;
    }

    final position = Duration(milliseconds: currPositionMs);

    await _stopPlayback();

    await widget.onPlay(position);

    _startMillisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    _startMediaPositionMs = currPositionMs;

    _animController.duration = Duration(milliseconds: (durationMs / _currentSpeed).toInt());
    _animController.reset();

    _animController.forward().then((_) {
      _stopPlayback();
    });

    setState(() {
      _isPlaying = true;
    });

    _updateOffset();
  }

  @override
  void dispose() {
    widget.onStop();
    _animController.removeListener(_updateOffset);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragUpdate: _onDragUpdate,
          child: ClipRect(
            child: CustomPaint(
              size: Size(widget.width, widget.height),
              painter: MediaBarPainter(
                offset: _blockOffset,
                mediaVerseStartMs: widget.verseStartMs,
                mediaVerseEndMs: widget.verseEndMs,
                mediaDurationMs: widget.duration(),
                hideTime: widget.hideTime,
              ),
            ),
          ),
        ),
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.replay_5),
                iconSize: 20,
                onPressed: () => _playAtPosition(incrementMs: -5000),
              ),
              IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 20,
                onPressed: playFromStart,
              ),
              IconButton(
                icon: const Icon(Icons.forward_5),
                iconSize: 20,
                onPressed: () => _playAtPosition(incrementMs: 5000),
              ),
              const Spacer(),
              if (widget.onEdit != null && !_isPlaying)
                IconButton(
                  icon: const Icon(Icons.cut),
                  iconSize: 20,
                  onPressed: () {
                    widget.onEdit!(widget.verseStartMs + (-_blockOffset / MediaBar.pixelPerMs).floor());
                  },
                ),
              if (widget.onAdjustSpeed != null)
                PopupMenuButton<double>(
                  icon: const Icon(Icons.speed, size: 20),
                  onSelected: (double speed) async {
                    await widget.onAdjustSpeed!(speed);
                    setState(() {
                      _currentSpeed = widget.getSpeed != null ? widget.getSpeed!() : speed;
                    });
                    if (_isPlaying) {
                      await _playAtPosition();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final currentSpeed = widget.getSpeed != null ? widget.getSpeed!() : _currentSpeed;
                    return [
                      PopupMenuItem<double>(
                        value: 0.25,
                        child: Text('0.25x', style: TextStyle(fontWeight: currentSpeed == 0.25 ? FontWeight.bold : FontWeight.normal)),
                      ),
                      PopupMenuItem<double>(
                        value: 0.5,
                        child: Text('0.5x', style: TextStyle(fontWeight: currentSpeed == 0.5 ? FontWeight.bold : FontWeight.normal)),
                      ),
                      PopupMenuItem<double>(
                        value: 0.75,
                        child: Text('0.75x', style: TextStyle(fontWeight: currentSpeed == 0.75 ? FontWeight.bold : FontWeight.normal)),
                      ),
                      PopupMenuItem<double>(
                        value: 1.0,
                        child: Text('Normal', style: TextStyle(fontWeight: currentSpeed == 1.0 ? FontWeight.bold : FontWeight.normal)),
                      ),
                      PopupMenuItem<double>(
                        value: 1.25,
                        child: Text('1.25x', style: TextStyle(fontWeight: currentSpeed == 1.25 ? FontWeight.bold : FontWeight.normal)),
                      ),
                      PopupMenuItem<double>(
                        value: 1.5,
                        child: Text('1.5x', style: TextStyle(fontWeight: currentSpeed == 1.5 ? FontWeight.bold : FontWeight.normal)),
                      ),
                      PopupMenuItem<double>(
                        value: 1.75,
                        child: Text('1.75x', style: TextStyle(fontWeight: currentSpeed == 1.75 ? FontWeight.bold : FontWeight.normal)),
                      ),
                      PopupMenuItem<double>(
                        value: 2.0,
                        child: Text('2.0x', style: TextStyle(fontWeight: currentSpeed == 2.0 ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ];
                  },
                ),
              IconButton(
                icon: _isPlaying ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                iconSize: 20,
                onPressed: _isPlaying ? _stopPlayback : () => _playAtPosition(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onDragStart(DragStartDetails details) {
    _previousDragOffset = details.localPosition.dx;
    _stopPlayback();
  }

  void _onDragEnd(DragEndDetails details) {
    _playAtPosition();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final currentOffset = details.localPosition.dx;
    final delta = currentOffset - _previousDragOffset;

    setState(() {
      _blockOffset += delta;
      _previousDragOffset = currentOffset;
    });
  }
}

class MediaBarPainter extends CustomPainter {
  static const double lineWidth = 30;
  static const double gapWidth = 30;
  static const double totalWidth = lineWidth + gapWidth;

  final double offset;
  final int mediaVerseStartMs;
  final int mediaVerseEndMs;
  final int mediaDurationMs;
  final bool hideTime;

  late final Paint _centerLinePaint;
  late final Paint _gridLinePaint;
  late final Paint _highlightPaint;

  MediaBarPainter({
    required this.offset,
    required this.mediaVerseStartMs,
    required this.mediaVerseEndMs,
    required this.mediaDurationMs,
    required this.hideTime,
  }) {
    _centerLinePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    _gridLinePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.0;

    _highlightPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final textHeight = _drawTimeText(canvas, size);
    _drawCenterLine(canvas, size, textHeight, 15, centerX);
    _drawTimeScale(canvas, 15, size);
  }

  void _drawCenterLine(Canvas canvas, Size size, double startY, double remainHeight, double centerX) {
    canvas.drawLine(
      Offset(centerX, startY),
      Offset(centerX, size.height - remainHeight),
      _centerLinePaint,
    );
  }

  void _drawTimeScale(Canvas canvas, start, Size size) {
    final centerX = size.width / 2;
    final currentTimeMs = mediaVerseStartMs + (-offset / MediaBar.pixelPerMs).floor();

    const tickIntervalMs = 1000;
    const minorTickIntervalMs = 200;

    final visibleTimeRangeStart = currentTimeMs - (size.width / 2 / MediaBar.pixelPerMs).floor();
    int firstTickTimeMs = visibleTimeRangeStart - (visibleTimeRangeStart % tickIntervalMs);
    if (firstTickTimeMs < 0) firstTickTimeMs = 0;

    var visibleTimeRangeEnd = currentTimeMs + (size.width / 2 / MediaBar.pixelPerMs).floor() + tickIntervalMs;
    if (visibleTimeRangeEnd > mediaDurationMs) visibleTimeRangeEnd = mediaDurationMs;
    final scaleY = size.height - start;

    final zeroX = centerX + (0 - currentTimeMs) * MediaBar.pixelPerMs;
    final startHighlightX = centerX + (mediaVerseStartMs - currentTimeMs) * MediaBar.pixelPerMs;
    final endHighlightX = centerX + (mediaVerseEndMs - currentTimeMs) * MediaBar.pixelPerMs;
    final durationX = centerX + (mediaDurationMs - currentTimeMs) * MediaBar.pixelPerMs;
    final double lineDrawStartX = max(0.0, zeroX);
    final double lineDrawEndX = min(size.width, durationX);
    if (lineDrawEndX > lineDrawStartX) {
      final double clampedHighlightStartX = startHighlightX.clamp(lineDrawStartX, lineDrawEndX);
      final double clampedHighlightEndX = endHighlightX.clamp(lineDrawStartX, lineDrawEndX);
      if (clampedHighlightStartX > lineDrawStartX) {
        canvas.drawLine(
          Offset(lineDrawStartX, scaleY),
          Offset(clampedHighlightStartX, scaleY),
          _gridLinePaint,
        );
      }
      if (clampedHighlightEndX > clampedHighlightStartX) {
        canvas.drawLine(
          Offset(clampedHighlightStartX, scaleY),
          Offset(clampedHighlightEndX, scaleY),
          _highlightPaint,
        );
      }
      if (lineDrawEndX > clampedHighlightEndX) {
        canvas.drawLine(
          Offset(clampedHighlightEndX, scaleY),
          Offset(lineDrawEndX, scaleY),
          _gridLinePaint,
        );
      }
    }

    for (int tickTimeMs = firstTickTimeMs; tickTimeMs <= visibleTimeRangeEnd; tickTimeMs += minorTickIntervalMs) {
      final tickX = centerX + (tickTimeMs - currentTimeMs) * MediaBar.pixelPerMs;

      double tickHeight;
      bool isMainTick = tickTimeMs % tickIntervalMs == 0;

      bool isInVerseRange = tickTimeMs >= mediaVerseStartMs && tickTimeMs <= mediaVerseEndMs;

      Color tickColor = isInVerseRange ? Colors.red.withValues(alpha: 0.6) : Colors.blue;

      if (isMainTick) {
        tickHeight = 10.0;
        if (!hideTime) {
          final minutes = (tickTimeMs / 60000).floor();
          final seconds = ((tickTimeMs % 60000) / 1000).floor();
          final timeLabel = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

          final textPainter = TextPainter(
            text: TextSpan(
              text: timeLabel,
              style: TextStyle(color: isInVerseRange ? Colors.red.withValues(alpha: 0.8) : Colors.blueGrey, fontSize: 9),
            ),
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();
          textPainter.paint(canvas, Offset(tickX - textPainter.width / 2, scaleY + 2));
        }
      } else {
        tickHeight = 5.0;
      }

      canvas.drawLine(
        Offset(tickX, scaleY - tickHeight),
        Offset(tickX, scaleY),
        Paint()
          ..color = tickColor
          ..strokeWidth = isMainTick ? 1.0 : 0.5,
      );
    }
  }

  double _drawTimeText(Canvas canvas, Size size) {
    if (hideTime) {
      return 0;
    }
    final elapsedTimeMs = (-offset / MediaBar.pixelPerMs).floor();

    final playPositionMs = mediaVerseStartMs + elapsedTimeMs;

    final minutes = (playPositionMs / 60000).floor();
    final seconds = ((playPositionMs % 60000) / 1000).floor();
    final milliseconds = ((playPositionMs % 1000) / 100).floor();

    final timeString = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$milliseconds";

    const labelStyle = TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold);
    final TextPainter templateTextPainter = TextPainter(
      text: const TextSpan(text: "00:00.0", style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final double fixedLabelWidth = templateTextPainter.width;
    final timeText = TextPainter(
      text: TextSpan(
        text: timeString,
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    );

    timeText.layout();

    timeText.paint(canvas, Offset(size.width / 2 - fixedLabelWidth / 2, 0));
    return timeText.height;
  }

  @override
  bool shouldRepaint(covariant MediaBarPainter oldDelegate) {
    return oldDelegate.mediaVerseStartMs != mediaVerseStartMs || //
        oldDelegate.mediaVerseEndMs != mediaVerseEndMs ||
        oldDelegate.mediaDurationMs != mediaDurationMs ||
        offset != oldDelegate.offset;
  }
}
