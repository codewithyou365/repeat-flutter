import 'package:get/get.dart';
import 'package:repeat_flutter/page/main/main_binding.dart';
import 'package:repeat_flutter/page/main/main_view.dart';

GetPage mainNav(String path) {
  return GetPage(
    name: path,
    page: () => MainPage(),
    binding: MainBinding(),
  );
}
