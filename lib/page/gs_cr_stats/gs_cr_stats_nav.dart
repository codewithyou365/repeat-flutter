import 'package:get/get.dart';
import 'gs_cr_stats_binding.dart';
import 'gs_cr_stats_view.dart';

GetPage gsCrStatsNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrStatsPage(),
    binding: GsCrStatsBinding(),
  );
}
