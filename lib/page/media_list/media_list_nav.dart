import 'package:get/get.dart';

import 'media_list_binding.dart';
import 'media_list_page.dart';

GetPage mediaListNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    page: () => const MediaListPage(),
    binding: MediaListBinding(),
  );
}
