import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'gs_cr_repeat_logic.dart';

mixin GsCrRepeatViewForPortrait {
  Widget buildForPortrait(BuildContext context) {
    final logic = Get.find<GsCrRepeatLogic>();
    final state = Get.find<GsCrRepeatLogic>().state;

    return GetBuilder<GsCrRepeatLogic>(
      id: GsCrRepeatLogic.id,
      builder: (_) {
        return Scaffold(body: Container());
      },
    );
  }
}
