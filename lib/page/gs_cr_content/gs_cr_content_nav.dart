import 'package:get/get.dart';
import 'gs_cr_content_binding.dart';
import 'gs_cr_content_view.dart';

GetPage gsCrContentNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrContentPage(),
    binding: GsCrContentBinding(),
  );
}
