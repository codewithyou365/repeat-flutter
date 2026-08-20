import 'package:get/get.dart';
import 'sc_cr_material_record_binding.dart';
import 'sc_cr_material_record_page.dart';

GetPage scCrMaterialRecordNav(String path) {
  return GetPage(
    name: path,
    // 录音会话是个独占的模式，用全屏对话框的形态，且禁掉侧滑返回：
    // 手一滑就把一整场录音丢了太危险，退出必须走显式的停止按钮。
    fullscreenDialog: true,
    popGesture: false,
    transition: Transition.fadeIn,
    page: () => const ScCrMaterialRecordPage(),
    binding: ScCrMaterialRecordBinding(),
  );
}
