import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_content/main_content_binding.dart';
import 'package:repeat_flutter/page/main_content/main_content_view.dart';

GetPage mainContentNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => MainContentPage(),
    binding: MainContentBinding(),
  );
}
