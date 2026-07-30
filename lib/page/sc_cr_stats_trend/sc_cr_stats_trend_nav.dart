import 'package:get/get.dart';
import 'sc_cr_stats_trend_binding.dart';
import 'sc_cr_stats_trend_page.dart';

GetPage scCrStatsTrendNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => const ScCrStatsTrendPage(),
    binding: ScCrStatsTrendBinding(),
  );
}
