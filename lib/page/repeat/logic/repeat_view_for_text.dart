import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'helper.dart';
import 'repeat_view.dart';

class RepeatViewForText extends RepeatView {
  RepeatViewForText();

  @override
  void init(Helper helper) {
    this.helper = helper;
  }

  @override
  void dispose() {}

  @override
  Widget body() {
    double height = 400;
    Helper? helper = this.helper;
    if (helper == null) {
      return SizedBox(height: height);
    }
    var verseContent = helper.getCurrVerseContent();
    if (verseContent == null) {
      return SizedBox(height: height);
    }

    double padding = 16;
    if (helper.landscape) {
      padding = helper.leftPadding;
    }
    height = helper.screenHeight - helper.topPadding - helper.topBarHeight - helper.bottomBarHeight;
    helper.bodyHeight = height;
    // 正文区里各字段的顺序由内容自己说了算（'o'，见 VerseField.orderOf）。
    // 整节媒体不在这里排——它是横跨所有字段的播放控制层，待在这个列表外的固定层里。
    var fieldAreas = helper.currFieldOrder().map(helper.fieldArea).nonNulls.toList();
    var practiceAreaWidget = helper.practiceArea.call();
    var tipAreaWidget = helper.tipArea.call();
    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: helper.topPadding),
            helper.topBar(),
            SizedBox(
              height: height,
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...fieldAreas,
                        if (practiceAreaWidget != null) practiceAreaWidget,
                        if (tipAreaWidget != null) tipAreaWidget,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            helper.bottomBar(width: helper.screenWidth),
          ],
        ),
        Obx(() {
          return helper.fullScreenPanel();
        }),
      ],
    );
  }
}
