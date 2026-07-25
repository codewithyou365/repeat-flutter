import 'package:get/get.dart';
import 'sc_cr_material_add_chapter_binding.dart';
import 'sc_cr_material_add_chapter_page.dart';

GetPage scCrMaterialAddChapterNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => const ScCrMaterialAddChapterPage(),
    binding: ScCrMaterialAddChapterBinding(),
  );
}
