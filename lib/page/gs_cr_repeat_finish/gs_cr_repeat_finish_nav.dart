import 'package:get/get.dart';
import 'gs_cr_repeat_finish_binding.dart';
import 'gs_cr_repeat_finish_view.dart';

GetPage gsCrRepeatFinishNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.downToUp,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrRepeatFinishPage(),
    binding: GsCrRepeatFinishBinding(),
  );
}
