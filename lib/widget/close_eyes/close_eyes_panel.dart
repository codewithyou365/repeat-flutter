import 'dart:async';

import 'package:flutter/material.dart';

class CloseEyesPanel {
  static Widget open({
    required double height,
    required double width,
    required DirectEnum direct,

    required void Function(DirectEnum direct) changeDirect,
    required void Function(int index) upCallback,
    required VoidCallback close,
    Color? backgroundColor,
    void Function(int index)? doubleUpCallback,
  }) {
    final Map<int, int> lastUpTime = {};
    final Map<int, Timer> pendingUpTimers = {};
    const delayTime = 300;
    return _MultiTouchArea(
      height: height,
      width: width,
      direct: direct,
      changeDirect: changeDirect,
      upCallback: (int index) {
        if (doubleUpCallback != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final last = lastUpTime[index];
          if (last != null && now - last < delayTime) {
            pendingUpTimers[index]?.cancel();
            pendingUpTimers.remove(index);

            doubleUpCallback(index);
          } else {
            pendingUpTimers[index]?.cancel();
            pendingUpTimers[index] = Timer(const Duration(milliseconds: delayTime), () {
              upCallback(index);
              pendingUpTimers.remove(index);
            });
          }
          lastUpTime[index] = now;
        } else {
          upCallback(index);
        }
      },
      close: close,
      backgroundColor: backgroundColor,
    );
  }
}

class _MultiTouchArea extends StatefulWidget {
  final double height;
  final double width;
  final DirectEnum direct;
  final void Function(DirectEnum direct) changeDirect;
  final void Function(int index) upCallback;
  final VoidCallback close;
  final Color? backgroundColor;

  const _MultiTouchArea({
    required this.height,
    required this.width,
    required this.direct,
    required this.changeDirect,
    required this.upCallback,
    required this.close,
    this.backgroundColor,
  });

  @override
  State<_MultiTouchArea> createState() => _MultiTouchAreaState();
}

enum DirectEnum {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

class _MultiTouchAreaState extends State<_MultiTouchArea> {
  final Map<int, Offset> _activeFingers = {};
  final Map<int, int> _fingerLabels = {};
  final bool show = true;
  late DirectEnum direct;

  @override
  void initState() {
    super.initState();
    direct = widget.direct;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activeFingers[event.pointer] = event.position;

    final sorted = _sort(_activeFingers.entries.toList(), direct);

    _fingerLabels
      ..clear()
      ..addEntries(
        sorted.asMap().entries.map(
          (e) => MapEntry(e.value.key, e.key),
        ),
      );

    setState(() {});
  }

  void _onPointerUp(PointerUpEvent event) {
    _activeFingers.remove(event.pointer);
    final label = _fingerLabels[event.pointer];
    if (label != null) {
      widget.upCallback(label);
    }
    setState(() {});
  }

  DirectEnum _nextDirection(DirectEnum d) {
    final values = DirectEnum.values;
    final nextIndex = (d.index + 1) % values.length;
    return values[nextIndex];
  }

  void _resetAndRotate() {
    if (_fingerLabels.isNotEmpty) {
      _activeFingers.clear();
      _fingerLabels.clear();
    } else {
      direct = _nextDirection(direct);
      widget.changeDirect(direct);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: widget.height,
              width: widget.width,
              color: widget.backgroundColor,
            ),
          ),
          if (show)
            ..._activeFingers.entries.map((entry) {
              final pointer = entry.key;
              final position = entry.value;
              final label = _fingerLabels[pointer];
              if (label == null) return const SizedBox.shrink();
              return Positioned(
                left: position.dx - 25,
                top: position.dy - 25,
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    '$label',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetAndRotate,
                ),
                _directionIcon(direct),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.close,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<int, Offset>> _sort(List<MapEntry<int, Offset>> list, DirectEnum d) {
    switch (d) {
      case DirectEnum.leftToRight:
        list.sort((a, b) => a.value.dx.compareTo(b.value.dx));
        break;
      case DirectEnum.rightToLeft:
        list.sort((a, b) => b.value.dx.compareTo(a.value.dx));
        break;
      case DirectEnum.topToBottom:
        list.sort((a, b) => a.value.dy.compareTo(b.value.dy));
        break;
      case DirectEnum.bottomToTop:
        list.sort((a, b) => b.value.dy.compareTo(a.value.dy));
        break;
    }
    return list;
  }

  Widget _directionIcon(DirectEnum d) {
    switch (d) {
      case DirectEnum.leftToRight:
        return Icon(Icons.keyboard_double_arrow_right_outlined);
      case DirectEnum.rightToLeft:
        return Icon(Icons.keyboard_double_arrow_left_outlined);
      case DirectEnum.topToBottom:
        return Icon(Icons.keyboard_double_arrow_down_outlined);
      case DirectEnum.bottomToTop:
        return Icon(Icons.keyboard_double_arrow_up_outlined);
    }
  }
}
