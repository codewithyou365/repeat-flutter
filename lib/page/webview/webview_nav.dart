import 'package:get/get.dart';
import 'webview_binding.dart';
import 'webview_page.dart';

GetPage webviewNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => WebviewPage(),
    binding: WebviewBinding(),
  );
}
