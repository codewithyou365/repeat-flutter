import 'package:get/get.dart';
import 'editor_binding.dart';
import 'editor_page.dart';

GetPage editorNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => EditorPage(),
    binding: EditorBinding(),
  );
}
