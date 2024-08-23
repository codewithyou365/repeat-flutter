import 'package:get/get.dart';
import 'gs_cr_content_scan_binding.dart';
import 'gs_cr_content_scan_view.dart';

GetPage gsCrContentScanNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrContentScanPage(),
    binding: GsCrContentScanBinding(),
  );
}
