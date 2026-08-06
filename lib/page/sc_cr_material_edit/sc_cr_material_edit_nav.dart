import 'package:get/get.dart';
import 'sc_cr_material_edit_binding.dart';
import 'sc_cr_material_edit_page.dart';

GetPage scCrMaterialEditNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => const ScCrMaterialEditPage(),
    binding: ScCrMaterialEditBinding(),
  );
}
