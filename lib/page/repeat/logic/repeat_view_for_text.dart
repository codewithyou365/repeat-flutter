import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'constant.dart';
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
    var q = helper.text(QaType.question);
    var t = helper.text(QaType.tip);
    var a = helper.text(QaType.answer);
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
                        if (q != null) q,
                        if (t != null) t,
                        if (a != null) a,
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
          return helper.closeEyesPanel();
        }),
      ],
    );
  }
}
