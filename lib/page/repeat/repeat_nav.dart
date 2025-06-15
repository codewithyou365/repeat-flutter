import 'package:get/get.dart';
import 'repeat_binding.dart';
import 'repeat_page.dart';

GetPage repeatNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => RepeatPage(),
    binding: RepeatBinding(),
  );
}
