import 'package:get/get.dart';
import 'gs_cr_binding.dart';
import 'gs_cr_view.dart';

GetPage gsCrNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrPage(),
    binding: GsCrBinding(),
  );
}
