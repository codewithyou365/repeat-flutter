import 'package:get/get.dart';
import 'sc_cr_binding.dart';
import 'sc_cr_page.dart';

GetPage scCrNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => ScCrPage(),
    binding: ScCrBinding(),
  );
}
