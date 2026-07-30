import 'package:get/get.dart';

import 'sc_cr_material_search_binding.dart';
import 'sc_cr_material_search_page.dart';

GetPage scCrMaterialSearchNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => const ScCrMaterialSearchPage(),
    binding: ScCrMaterialSearchBinding(),
  );
}
