import 'package:get/get.dart';
import 'sc_cr_material_binding.dart';
import 'sc_cr_material_view.dart';

GetPage scCrMaterialNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => ScCrMaterialPage(),
    binding: ScCrMaterialBinding(),
  );
}
