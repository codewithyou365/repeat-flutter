import 'package:get/get.dart';
import 'sc_cr_stats_review_binding.dart';
import 'sc_cr_stats_review_page.dart';

GetPage scCrStatsReviewNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => ScCrStatsReviewPage(),
    binding: ScCrStatsReviewBinding(),
  );
}
