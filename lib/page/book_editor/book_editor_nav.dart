import 'package:get/get.dart';
import 'book_editor_binding.dart';
import 'book_editor_page.dart';

GetPage bookEditorNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => BookEditorPage(),
    binding: BookEditorBinding(),
  );
}
