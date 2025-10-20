import 'package:get/get.dart';
import 'sc_cr_stats_detail_binding.dart';
import 'sc_cr_stats_detail_page.dart';

GetPage scCrStatsDetailNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => ScCrStatsDetailPage(),
    binding: ScCrStatsDetailBinding(),
  );
}
