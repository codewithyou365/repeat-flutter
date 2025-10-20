import 'package:get/get.dart';
import 'sc_cr_stats_binding.dart';
import 'sc_cr_stats_page.dart';

GetPage scCrStatsNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => ScCrStatsPage(),
    binding: ScCrStatsBinding(),
  );
}
