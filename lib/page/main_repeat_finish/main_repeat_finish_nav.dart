import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_repeat_finish/main_repeat_finish_binding.dart';
import 'package:repeat_flutter/page/main_repeat_finish/main_repeat_finish_view.dart';

GetPage mainRepeatFinishNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => MainRepeatFinishPage(),
    binding: MainRepeatFinishBinding(),
  );
}
