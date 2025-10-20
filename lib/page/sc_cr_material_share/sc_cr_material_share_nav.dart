import 'package:get/get.dart';
import 'sc_cr_material_share_binding.dart';
import 'sc_cr_material_share_page.dart';

GetPage scCrMaterialShareNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => ScCrContentSharePage(),
    binding: ScCrMaterialShareBinding(),
  );
}
