import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final String selectText;
  final int limit;
  final TextStyle? style;
  final TextStyle? selectedStyle;
  final VoidCallback? onEdit;

  const ExpandableText({
    Key? key,
    required this.text,
    this.selectText = "",
    required this.limit,
    this.style,
    this.selectedStyle,
    this.onEdit,
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
    if (!isExpanded) {
      int newLineIndex = displayText.indexOf('\n');
      if (newLineIndex != -1) {
        displayText = displayText.substring(0, newLineIndex);
      }
      if (displayText.length > widget.limit) {
        displayText = displayText.substring(0, widget.limit);
      }
    }

    final startIndex = fullText.indexOf(selectText);
    final displayTextStartIndex = displayText.indexOf(selectText);

    List<InlineSpan> spans;
    String suffix = "";
    if (displayText != fullText) {
      suffix = "...";
    }

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
            text: displayText.substring(displayTextStartIndex + selectText.length) + suffix,
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
      spans = [
        TextSpan(
          text: displayText + suffix,
          style: widget.style,
        ),
      ];
    }

    if (widget.onEdit != null && displayText == fullText) {
      spans.add(
        WidgetSpan(
          child: GestureDetector(
            onTap: widget.onEdit,
            child: Container(
              width: 25,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF007BFF), width: 1)),
              ),
              child: const Icon(
                Icons.edit,
                color: Color(0xFF007BFF),
                size: 16, // Adjusted icon size
              ),
            ),
          ),
        ),
      );
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
