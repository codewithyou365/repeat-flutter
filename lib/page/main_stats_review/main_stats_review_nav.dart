import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_stats_review/main_stats_review_binding.dart';
import 'package:repeat_flutter/page/main_stats_review/main_stats_review_view.dart';

GetPage mainStatsReviewNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => MainStatsReviewPage(),
    binding: MainStatsReviewBinding(),
  );
}
