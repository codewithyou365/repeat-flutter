import 'package:get/get.dart';
import 'gs_cr_stats_learn_binding.dart';
import 'gs_cr_stats_learn_view.dart';

GetPage gsCrStatsLearnNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrStatsLearnPage(),
    binding: GsCrStatsLearnBinding(),
  );
}
