import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/entity/segment_key.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int limit;
  final TextStyle? style;

  const ExpandableText({
    Key? key,
    required this.text,
    required this.limit,
    this.style,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayText = isExpanded ? widget.text : StringUtil.limit(widget.text, widget.limit);

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Text(
        displayText,
        style: widget.style,
      ),
    );
  }
}

class WarningSegment {
  show(List<SegmentKey> sk) {
    Sheet.withHeaderAndBody(
      Get.context!,
      Column(
        key: GlobalKey(),
        mainAxisSize: MainAxisSize.min,
        children: [
          RowWidget.buildButtons([
            Button(I18nKey.btnClose.tr),
          ]),
          RowWidget.buildDivider(),
        ],
      ),
      ListView.builder(
        itemCount: sk.length,
        itemBuilder: (context, index) {
          final segmentKey = sk[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExpandableText(
                    text: '${I18nKey.labelKey.tr}: ${segmentKey.key}',
                    limit: 40,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ExpandableText(
                    text: '${I18nKey.labelSegmentName.tr}: ${segmentKey.segmentContent}',
                    limit: 80,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${I18nKey.labelPosition.tr}: ${segmentKey.toShortPos()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
