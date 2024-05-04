import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_stats/main_stats_binding.dart';
import 'package:repeat_flutter/page/main_stats/main_stats_view.dart';

GetPage mainStatsNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => MainStatsPage(),
    binding: MainStatsBinding(),
  );
}
