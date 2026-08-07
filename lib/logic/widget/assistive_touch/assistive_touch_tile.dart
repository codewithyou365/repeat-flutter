import 'package:flutter/material.dart';

class AssistiveTouchTile {
  /// 一行放几个。文案（尤其是"后退-<提示名>"这种带目标后缀的）比图标宽得多，
  /// 一行 4 个必截断，所以按 3 个排，宽度按可用宽度均分——不写死像素，
  /// 横竖屏、不同机型都对得上。
  static const int columns = 3;
  static const double spacing = 16;

  /// [available] 是这一行能用的宽度（LayoutBuilder 的 maxWidth，已经扣掉外面的 padding）。
  static double widthFor(double available) => (available - spacing * (columns - 1)) / columns;

  static Widget build({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool enabled = true,
    double width = 72,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
