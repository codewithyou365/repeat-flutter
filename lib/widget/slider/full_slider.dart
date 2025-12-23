import 'package:flutter/material.dart';

class FullSlider extends StatefulWidget {
  final double width;
  final double height;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const FullSlider({
    required this.width,
    required this.height,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    super.key,
  });

  @override
  State<FullSlider> createState() => _FullSliderState();
}

class _FullSliderState extends State<FullSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  double _snap(double v) {
    final step = (widget.max - widget.min) / widget.divisions;
    return (widget.min + ((v - widget.min) / step).round() * step).clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final percent = (_value - widget.min) / (widget.max - widget.min);
    final thumbX = percent * width;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        final dx = details.localPosition.dx.clamp(0.0, width);
        final rawValue = widget.min + (dx / width) * (widget.max - widget.min);
        final snapped = _snap(rawValue);

        setState(() => _value = snapped);
        widget.onChanged(snapped);
      },
      onHorizontalDragEnd: (_) {
        widget.onChangeEnd?.call(_value);
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            width: width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Theme.of(context).secondaryHeaderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Positioned(
            left: 0,
            width: thumbX,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          ...List.generate(
            widget.divisions + 1,
            (i) => Positioned(
              left: (i / widget.divisions) * width,
              child: Container(
                width: 1,
                height: widget.height,
                color: Theme.of(context).primaryColor.withAlpha(100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
