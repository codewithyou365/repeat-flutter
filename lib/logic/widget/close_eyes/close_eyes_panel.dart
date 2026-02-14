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
    required void Function(int index, int total) doubleUpCallback,
  }) {
    final Map<int, int> lastUpTime = {};
    final Map<int, Timer> pendingUpTimers = {};
    const delayTime = 300;

    return _MultiTouchArea(
      height: height,
      width: width,
      showFinger: showFinger,
      direct: direct,
      changeDirect: changeDirect,
      upCallback: (int index, int total) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final last = lastUpTime[index];
        if (last != null && now - last < delayTime) {
          pendingUpTimers[index]?.cancel();
          pendingUpTimers.remove(index);

          doubleUpCallback(index, total);
        } else {
          pendingUpTimers[index]?.cancel();
          pendingUpTimers[index] = Timer(const Duration(milliseconds: delayTime), () {
            pendingUpTimers.remove(index);
          });
        }
        lastUpTime[index] = now;
      },
      doubleUpCallback: doubleUpCallback,
      close: close,
      help: help,
      key: key,
    );
  }
}

class _MultiTouchArea extends StatefulWidget {
  final double height;
  final double width;
  final bool showFinger;
  final DirectEnum direct;
  final void Function(DirectEnum direct) changeDirect;
  final void Function(int index, int total) upCallback;
  final void Function(int index, int total) doubleUpCallback;
  final VoidCallback close;
  final VoidCallback help;

  const _MultiTouchArea({
    required this.height,
    required this.width,
    required this.showFinger,
    required this.direct,
    required this.changeDirect,
    required this.upCallback,
    required this.doubleUpCallback,
    required this.close,
    required this.help,
    required super.key,
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
  RxBool show = false.obs;
  RxBool showButton = false.obs;

  Rx<CloseEyesModeEnum> closeEyesMode = CloseEyesModeEnum.opacity.obs;

  late Rx<DirectEnum> direct;

  @override
  void initState() {
    super.initState();
    show.value = widget.showFinger;
    direct = Rx(widget.direct);
    _guard.enableSecureFlag(enable: true);
  }

  @override
  void dispose() {
    _guard.enableSecureFlag(enable: false);
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _activeFingers[event.pointer] = event.position;

    final sorted = _sort(_activeFingers.entries.toList(), direct.value);

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
    direct.value = _nextDirection(direct.value);
    widget.changeDirect(direct.value);
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
            child: Container(
              height: widget.height,
              width: widget.width,
              color: closeEyesMode.value.backgroundColor,
            ),
          ),
          if (show.value)
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
            child: Obx(() {
              if (direct.value == DirectEnum.bottomToTop || direct.value == DirectEnum.topToBottom) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showButton.value)
                      ...List.generate(
                        4,
                        (index) {
                          final isNormalOrder = direct.value == DirectEnum.topToBottom;
                          final i = isNormalOrder ? index : (3 - index);
                          return buildButton(i);
                        },
                      ),
                    buildMenu(),
                  ],
                );
              } else {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showButton.value)
                      ...List.generate(
                        4,
                        (index) {
                          final isNormalOrder = direct.value == DirectEnum.leftToRight;
                          final i = isNormalOrder ? index : (3 - index);
                          return buildButton(i);
                        },
                      ),
                    buildMenu(),
                  ],
                );
              }
            }),
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

  Widget buildButton(int index) {
    return Expanded(
      child: TextButton(
        onPressed: () => widget.doubleUpCallback.call(index, 4),
        child: Text(
          '${index + 1}',
          style: TextStyle(color: closeEyesMode.value.foregroundColor),
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: loopCloseEyesMode,
            child: Obx(() {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${I18nKey.closeEyesMode.tr}${i18nCloseEyesMode()}"),
                  Spacer(),
                ],
              );
            }),
          ),
        ),
        PopupMenuItem<String>(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => show.value = !show.value,
            child: Obx(() {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${I18nKey.showFingers.tr}($show)"),
                  Spacer(),
                ],
              );
            }),
          ),
        ),

        PopupMenuItem<String>(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showButton.value = !showButton.value,
            child: Obx(() {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${I18nKey.showButtons.tr}($showButton)"),
                  Spacer(),
                ],
              );
            }),
          ),
        ),
        PopupMenuItem<String>(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: rotate,
            child: Obx(() {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${I18nKey.rotate.tr} :"),
                  SizedBox(width: 2),
                  _directionIcon(direct.value),
                  Spacer(),
                ],
              );
            }),
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
        return const Icon(
          Icons.keyboard_double_arrow_right_outlined,
        );
      case DirectEnum.rightToLeft:
        return const Icon(
          Icons.keyboard_double_arrow_left_outlined,
        );
      case DirectEnum.topToBottom:
        return const Icon(
          Icons.keyboard_double_arrow_down_outlined,
        );
      case DirectEnum.bottomToTop:
        return const Icon(
          Icons.keyboard_double_arrow_up_outlined,
        );
    }
  }
}
