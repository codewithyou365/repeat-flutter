import 'package:flutter/widgets.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final String selectText;
  final int limit;
  final TextStyle? style;
  final TextStyle? selectedStyle;

  const ExpandableText({
    Key? key,
    required this.text,
    this.selectText = "",
    required this.limit,
    this.style,
    this.selectedStyle,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final fullText = widget.text;
    final selectText = widget.selectText;

    String displayText = fullText;
    if (!isExpanded && fullText.length > widget.limit) {
      displayText = fullText.substring(0, widget.limit);
    }

    final startIndex = fullText.indexOf(selectText);
    final displayTextStartIndex = displayText.indexOf(selectText);

    List<TextSpan> spans;

    if (selectText.isNotEmpty && startIndex != -1) {
      if (displayTextStartIndex != -1) {
        spans = [
          TextSpan(
            text: displayText.substring(0, displayTextStartIndex),
            style: widget.style,
          ),
          TextSpan(
            text: selectText,
            style: widget.selectedStyle ?? widget.style?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: displayText.substring(displayTextStartIndex + selectText.length),
            style: widget.style,
          ),
        ];
      } else {
        spans = [
          TextSpan(
            text: displayText,
            style: widget.style,
          ),
          TextSpan(
            text: '...',
            style: widget.selectedStyle ?? widget.style?.copyWith(fontWeight: FontWeight.bold),
          ),
        ];
      }
    } else {
      String suffix = "";
      if (displayText != fullText) {
        suffix = "...";
      }
      spans = [
        TextSpan(
          text: displayText + suffix,
          style: widget.style,
        ),
      ];
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Text.rich(
        TextSpan(children: spans),
      ),
    );
  }
}
