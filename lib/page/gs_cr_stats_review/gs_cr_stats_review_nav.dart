import 'package:get/get.dart';
import 'gs_cr_stats_review_binding.dart';
import 'gs_cr_stats_review_view.dart';

GetPage gsCrStatsReviewNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrStatsReviewPage(),
    binding: GsCrStatsReviewBinding(),
  );
}
