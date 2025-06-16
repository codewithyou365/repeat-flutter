import 'package:get/get.dart';
import 'scan_binding.dart';
import 'scan_page.dart';

GetPage scanNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => ScanPage(),
    binding: ScanBinding(),
  );
}
