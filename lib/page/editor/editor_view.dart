import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'editor_logic.dart';

class EditorPage extends StatelessWidget {
  EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<EditorLogic>();
    final state = logic.state;
    final Size screenSize = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double inset = MediaQuery.of(context).viewInsets.bottom;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    var landscape = false;
    if (screenWidth > screenHeight) {
      landscape = true;
    }
    double topBarHeight = 50;
    double topBottomHeight = 50;
    double bodyHeight = screenHeight - topPadding - topBarHeight - topBottomHeight - RowWidget.dividerHeight - inset;
    double bodyWidth = screenWidth;
    if (landscape) {
      bodyWidth = screenWidth - leftPadding * 2;
    }
    final List<Button> taps = [];
    if (state.historyBtn != null) {
      taps.add(state.historyBtn!);
    }
    taps.add(state.scanBtn);
    taps.add(state.save);
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: topPadding),
          topBar(
            context: context,
            logic: logic,
            width: screenWidth,
            height: topBarHeight,
          ),
          RowWidget.buildDividerWithoutColor(),
          SizedBox(
            height: bodyHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                controller: logic.textController,
                maxLines: 100,
                minLines: 50,
                autofocus: true,
              ),
            ),
          ),
          SizedBox(
            width: bodyWidth,
            height: topBottomHeight,
            child: Row(
              children: [
                ...List.generate(taps.length, (i) {
                  return Expanded(
                    child: Obx(() {
                      final theme = Theme.of(Get.context!);
                      return TextButton(
                        onPressed: taps[i].enable.value ? taps[i].onPressed : null,
                        child: Text(
                          taps[i].title,
                          style: TextStyle(
                            fontSize: 16,
                            color: taps[i].enable.value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget topBar({
    required BuildContext context,
    required EditorLogic logic,
    required double width,
    required double height,
  }) {
    var state = logic.state;

    const padding = 10.0;
    final icon = height;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Row(
            children: [
              const SizedBox(width: padding),
              SizedBox(
                width: icon,
                height: icon,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () {
                    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                    if (bottomInset > 0) {
                      FocusScope.of(context).unfocus();
                    } else {
                      Nav.back();
                    }
                  },
                ),
              ),
              Spacer(),
              SizedBox(
                width: icon,
                height: icon,
                child: Obx(() {
                  final theme = Theme.of(Get.context!);
                  return IconButton(
                    icon: const Icon(Icons.share),
                    color: state.shareBtn.enable.value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    onPressed: state.shareBtn.onPressed,
                  );
                }),
              ),
              const SizedBox(width: padding),
            ],
          ),
          Row(
            children: [
              Spacer(),
              SizedBox(
                height: height,
              ),
              Text(
                state.title,
                style: TextStyle(fontSize: 18),
              ),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
