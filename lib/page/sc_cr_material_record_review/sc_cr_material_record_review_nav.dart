import 'package:get/get.dart';
import 'sc_cr_material_record_review_binding.dart';
import 'sc_cr_material_record_review_page.dart';

GetPage scCrMaterialRecordReviewNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => const ScCrMaterialRecordReviewPage(),
    binding: ScCrMaterialRecordReviewBinding(),
  );
}
