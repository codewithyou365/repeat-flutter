import 'dart:async';

import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

class CloseEyesPanel {
  static Widget open({
    required double height,
    required double width,
    required DirectEnum direct,

    required void Function(DirectEnum direct) changeDirect,
    required void Function(int index, int total) upCallback,
    required VoidCallback close,
    required VoidCallback help,
    Color? backgroundColor,
    Color? foregroundColor,
    void Function(int index, int total)? doubleUpCallback,
  }) {
    final Map<int, int> lastUpTime = {};
    final Map<int, Timer> pendingUpTimers = {};
    const delayTime = 300;
    return _MultiTouchArea(
      height: height,
      width: width,
      direct: direct,
      changeDirect: changeDirect,
      upCallback: (int index, int total) {
        if (doubleUpCallback != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final last = lastUpTime[index];
          if (last != null && now - last < delayTime) {
            pendingUpTimers[index]?.cancel();
            pendingUpTimers.remove(index);

            doubleUpCallback(index, total);
          } else {
            pendingUpTimers[index]?.cancel();
            pendingUpTimers[index] = Timer(const Duration(milliseconds: delayTime), () {
              upCallback(index, total);
              pendingUpTimers.remove(index);
            });
          }
          lastUpTime[index] = now;
        } else {
          upCallback(index, total);
        }
      },
      close: close,
      help: help,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

class _MultiTouchArea extends StatefulWidget {
  final double height;
  final double width;
  final DirectEnum direct;
  final void Function(DirectEnum direct) changeDirect;
  final void Function(int index, int total) upCallback;
  final VoidCallback close;
  final VoidCallback help;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const _MultiTouchArea({
    required this.height,
    required this.width,
    required this.direct,
    required this.changeDirect,
    required this.upCallback,
    required this.close,
    required this.help,
    this.backgroundColor,
    this.foregroundColor,
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
  bool show = false;

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
      widget.upCallback(label, _fingerLabels.length);
    }
    setState(() {});
  }

  DirectEnum _nextDirection(DirectEnum d) {
    final values = DirectEnum.values;
    final nextIndex = (d.index + 1) % values.length;
    return values[nextIndex];
  }

  void rotate() {
    direct = _nextDirection(direct);
    widget.changeDirect(direct);
    setState(() {});
  }

  void clearFingers() {
    _activeFingers.clear();
    _fingerLabels.clear();
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
                    '${label + 1}',
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
            child: PopupMenuButton<String>(
              onOpened: clearFingers,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  onTap: widget.help,
                  child: Text(I18nKey.help.tr),
                ),
                PopupMenuItem<String>(
                  onTap: () => show = !show,
                  child: Text("${I18nKey.showFingers.tr}($show)"),
                ),
                PopupMenuItem<String>(
                  onTap: rotate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${I18nKey.rotate.tr} :"),
                      SizedBox(width: 2),
                      _directionIcon(direct),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  onTap: widget.close,
                  child: Text(I18nKey.close.tr),
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
        return Icon(
          Icons.keyboard_double_arrow_right_outlined,
          color: widget.foregroundColor,
        );
      case DirectEnum.rightToLeft:
        return Icon(
          Icons.keyboard_double_arrow_left_outlined,
          color: widget.foregroundColor,
        );
      case DirectEnum.topToBottom:
        return Icon(
          Icons.keyboard_double_arrow_down_outlined,
          color: widget.foregroundColor,
        );
      case DirectEnum.bottomToTop:
        return Icon(
          Icons.keyboard_double_arrow_up_outlined,
          color: widget.foregroundColor,
        );
    }
  }
}
