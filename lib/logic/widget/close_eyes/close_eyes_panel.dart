import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:screenshot_guard/screenshot_guard.dart';

final _guard = ScreenshotGuard();

class CloseEyesPanel {
  static Widget build({
    required Key key,
    required double height,
    required double width,
    required bool showFinger,
    required DirectEnum direct,
    required void Function(DirectEnum direct) changeDirect,
    required VoidCallback close,
    required VoidCallback help,
    required String Function(int index, int total) getName,
    required Color Function(int index, int total) getColor,
    required void Function(int index, int total) doubleUpCallback,
  }) {
    return _MultiTouchArea(
      height: height,
      width: width,
      showFinger: showFinger,
      direct: direct,
      changeDirect: changeDirect,
      getName: getName,
      getColor: getColor,
      doubleUpCallback: doubleUpCallback,
      close: close,
      help: help,
      key: key,
    );
  }
}

enum DirectEnum {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

class _MultiTouchArea extends StatefulWidget {
  final double height;
  final double width;
  final bool showFinger;
  final DirectEnum direct;
  final void Function(DirectEnum direct) changeDirect;
  final String Function(int index, int total) getName;
  final Color Function(int index, int total) getColor;
  final void Function(int index, int total) doubleUpCallback;
  final VoidCallback close;
  final VoidCallback help;

  const _MultiTouchArea({
    required this.height,
    required this.width,
    required this.showFinger,
    required this.direct,
    required this.changeDirect,
    required this.getName,
    required this.getColor,
    required this.doubleUpCallback,
    required this.close,
    required this.help,
    required super.key,
  });

  @override
  State<_MultiTouchArea> createState() => _MultiTouchAreaState();
}

class _MultiTouchAreaState extends State<_MultiTouchArea> {
  final Map<int, Offset> _activeFingers = {};
  final Map<int, int> _fingerLabels = {};

  final Map<int, int> _lastUpTime = {};
  final Map<int, Timer> _pendingUpTimers = {};
  static const int _delayTime = 300;

  final RxBool showFinger = false.obs;
  final RxBool showButton = false.obs;
  final Rx<CloseEyesModeEnum> closeEyesMode = CloseEyesModeEnum.opacity.obs;
  late Rx<DirectEnum> direct;

  @override
  void initState() {
    super.initState();
    showFinger.value = widget.showFinger;
    direct = Rx(widget.direct);
    _guard.enableSecureFlag(enable: true);
  }

  @override
  void dispose() {
    _guard.enableSecureFlag(enable: false);
    for (var timer in _pendingUpTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _handleUpEvent(int label, int total) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastUpTime[label];

    if (last != null && now - last < _delayTime) {
      _pendingUpTimers[label]?.cancel();
      _pendingUpTimers.remove(label);
      widget.doubleUpCallback(label, total);
    } else {
      _pendingUpTimers[label]?.cancel();
      _pendingUpTimers[label] = Timer(const Duration(milliseconds: _delayTime), () {
        _pendingUpTimers.remove(label);
      });
    }
    _lastUpTime[label] = now;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activeFingers[event.pointer] = event.position;
    _updateLabels();
    setState(() {});
  }

  void _onPointerUp(PointerUpEvent event) {
    final label = _fingerLabels[event.pointer];
    final total = _activeFingers.length;

    if (label != null) {
      _handleUpEvent(label, total);
    }

    _activeFingers.remove(event.pointer);
    _updateLabels();
    setState(() {});
  }

  void _updateLabels() {
    final sorted = _sort(_activeFingers.entries.toList(), direct.value);
    _fingerLabels.clear();
    for (int i = 0; i < sorted.length; i++) {
      _fingerLabels[sorted[i].key] = i;
    }
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

  void rotate() {
    final values = DirectEnum.values;
    final nextIndex = (direct.value.index + 1) % values.length;
    direct.value = values[nextIndex];
    widget.changeDirect(direct.value);
    _updateLabels();
    setState(() {});
  }

  void reset() {
    _activeFingers.clear();
    _fingerLabels.clear();
    setState(() {});
  }

  void loopCloseEyesMode() {
    switch (closeEyesMode.value) {
      case CloseEyesModeEnum.opacity:
        closeEyesMode.value = CloseEyesModeEnum.translucence;
        break;
      case CloseEyesModeEnum.translucence:
        closeEyesMode.value = CloseEyesModeEnum.transparent;
        break;
      default:
        closeEyesMode.value = CloseEyesModeEnum.opacity;
        break;
    }
    setState(() {});
  }

  String i18nCloseEyesMode() {
    switch (closeEyesMode.value) {
      case CloseEyesModeEnum.opacity:
        return I18nKey.opacity.tr;
      case CloseEyesModeEnum.translucence:
        return I18nKey.translucence.tr;
      default:
        return I18nKey.transparent.tr;
    }
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
            child: Obx(
              () => Container(
                height: widget.height,
                width: widget.width,
                color: closeEyesMode.value.backgroundColor,
              ),
            ),
          ),

          // 手指位置显示
          Obx(
            () => showFinger.value
                ? Stack(
                    children: _activeFingers.entries.map((entry) {
                      final label = _fingerLabels[entry.key];
                      if (label == null) return const SizedBox.shrink();

                      final color = widget.getColor(label, 4);

                      return Positioned(
                        left: entry.value.dx - 35,
                        top: entry.value.dy - 35,
                        child: Container(
                          width: 70,
                          height: 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.5),
                            border: Border.all(color: Colors.white70, width: 2),
                          ),
                          child: Text(
                            widget.getName(label, _activeFingers.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const SizedBox.shrink(),
          ),

          // 底部控制栏
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Obx(() {
              bool isVertical = direct.value == DirectEnum.bottomToTop || direct.value == DirectEnum.topToBottom;

              List<Widget> children = [];
              if (showButton.value) {
                const totalButtons = 4; // 假设固定 4 个按钮
                var buttons = List.generate(totalButtons, (index) {
                  final isReverse = direct.value == DirectEnum.rightToLeft || direct.value == DirectEnum.bottomToTop;
                  final i = isReverse ? (totalButtons - 1 - index) : index;
                  return buildButton(i);
                });
                children.addAll(buttons);
              }
              children.add(buildMenu());

              return isVertical ? Column(mainAxisSize: MainAxisSize.min, children: children) : Row(mainAxisSize: MainAxisSize.min, children: children);
            }),
          ),
        ],
      ),
    );
  }

  Widget buildButton(int index) {
    final color = widget.getColor(index, _activeFingers.length);
    return Expanded(
      child: TextButton(
        onPressed: () => widget.doubleUpCallback.call(index, 4),
        child: Text(
          '$index ${widget.getName(index, 4)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildMenu() {
    return PopupMenuButton<String>(
      onOpened: reset,
      icon: Icon(Icons.more_vert, color: closeEyesMode.value.foregroundColor),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          onTap: widget.help,
          child: Text(I18nKey.help.tr),
        ),
        PopupMenuItem<String>(
          onTap: loopCloseEyesMode,
          child: Obx(() => Text("${I18nKey.closeEyesMode.tr}: ${i18nCloseEyesMode()}")),
        ),
        PopupMenuItem<String>(
          onTap: () => showFinger.value = !showFinger.value,
          child: Obx(() => Text("${I18nKey.showFingers.tr}: ${showFinger.value}")),
        ),
        PopupMenuItem<String>(
          onTap: () => showButton.value = !showButton.value,
          child: Obx(() => Text("${I18nKey.showButtons.tr}: ${showButton.value}")),
        ),
        PopupMenuItem<String>(
          onTap: rotate,
          child: Row(
            children: [
              Text("${I18nKey.rotate.tr}: "),
              const SizedBox(width: 8),
              Obx(() => _directionIcon(direct.value)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: widget.close,
          child: Text(I18nKey.close.tr),
        ),
      ],
    );
  }

  Widget _directionIcon(DirectEnum d) {
    switch (d) {
      case DirectEnum.leftToRight:
        return const Icon(Icons.keyboard_double_arrow_right_outlined);
      case DirectEnum.rightToLeft:
        return const Icon(Icons.keyboard_double_arrow_left_outlined);
      case DirectEnum.topToBottom:
        return const Icon(Icons.keyboard_double_arrow_down_outlined);
      case DirectEnum.bottomToTop:
        return const Icon(Icons.keyboard_double_arrow_up_outlined);
    }
  }
}
