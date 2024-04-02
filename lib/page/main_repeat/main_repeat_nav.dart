import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_repeat/main_repeat_binding.dart';
import 'package:repeat_flutter/page/main_repeat/main_repeat_view.dart';

GetPage mainRepeatNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => MainRepeatPage(),
    binding: MainRepeatBinding(),
  );
}
