import 'package:get/get.dart';
import 'sc_share_binding.dart';
import 'sc_share_page.dart';

GetPage scShareNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => const ScSharePage(),
    binding: ScShareBinding(),
  );
}
