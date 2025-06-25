import 'dart:io';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/sc_cr_material/sc_cr_material_logic.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';

import 'gs_cr_content_template_state.dart';

class GsCrContentTemplateLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentTemplateState state = GsCrContentTemplateState();

  @override
  void onInit() {
    super.onInit();
    List<int> ids = Get.arguments as List<int>;
    state.bookId = ids[0];
    for (var v in RepeatViewEnum.values) {
      state.items.add(v.name);
    }
  }

  Future<void> onSave(String name) async {

    Get.back(result: name);
  }
}
