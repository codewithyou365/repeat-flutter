import 'package:get/get.dart';
import 'gs_cr_stats_detail_binding.dart';
import 'gs_cr_stats_detail_view.dart';

GetPage gsCrStatsDetailNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrStatsDetailPage(),
    binding: GsCrStatsDetailBinding(),
  );
}
