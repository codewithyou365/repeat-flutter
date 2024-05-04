import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_stats_learn/main_stats_learn_binding.dart';
import 'package:repeat_flutter/page/main_stats_learn/main_stats_learn_view.dart';

GetPage mainStatsLearnNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => MainStatsLearnPage(),
    binding: MainStatsLearnBinding(),
  );
}
