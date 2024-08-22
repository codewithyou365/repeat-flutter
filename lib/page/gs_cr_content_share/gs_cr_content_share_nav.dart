import 'package:get/get.dart';
import 'gs_cr_content_share_binding.dart';
import 'gs_cr_content_share_view.dart';

GetPage gsCrContentShareNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrContentSharePage(),
    binding: GsCrContentShareBinding(),
  );
}
