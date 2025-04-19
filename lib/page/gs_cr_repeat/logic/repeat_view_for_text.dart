import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
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
  Widget body({required double height}) {
    Helper? helper = this.helper;
    if (helper == null) {
      return SizedBox(height: height);
    }
    var segmentContent = helper.getCurrSegmentContent();
    if (segmentContent == null) {
      return SizedBox(height: height);
    }
    double padding = 16;
    double top = 0;
    if (helper.landscape) {
      padding = MediaQuery.of(Get.context!).padding.left;
      top = helper.topBarHeight;
    }
    Segment s = Segment.fromJson(jsonDecode(segmentContent));
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding, top, padding, 0),
        child: ListView(padding: const EdgeInsets.all(0), children: [
          if (s.question != null && s.question!.isNotEmpty) Text(s.question!),
          if (helper.step != RepeatStep.recall) Text(s.answer),
        ]),
      ),
    );
  }
}
