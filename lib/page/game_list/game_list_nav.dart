import 'package:get/get.dart';

import 'game_list_binding.dart';
import 'game_list_page.dart';

GetPage gameListNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    page: () => const GameListPage(),
    binding: GameListBinding(),
  );
}
