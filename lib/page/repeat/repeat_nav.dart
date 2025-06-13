import 'package:get/get.dart';
import 'gs_cr_repeat_binding.dart';
import 'gs_cr_repeat_view.dart';

GetPage repeatNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsCrRepeatPage(),
    binding: GsCrRepeatBinding(),
  );
}
