import 'package:get/get.dart';

import 'sc_binding.dart';
import 'sc_page.dart';

GetPage scNav(String path) {
  return GetPage(
    name: path,
    page: () => ScPage(),
    binding: ScBinding(),
  );
}
