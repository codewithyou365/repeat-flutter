import 'package:get/get.dart';

class WebviewState {
  // 加载进度
  final RxDouble progress = 0.0.obs;

  // 是否正在加载
  final RxBool isLoading = true.obs;

  // 当前页面标题
  final RxString title = ''.obs;

  // 当前 URL
  final RxString currentUrl = ''.obs;

  // 是否可以后退
  final RxBool canGoBack = false.obs;

  // 是否可以前进
  final RxBool canGoForward = false.obs;

  WebviewState() {
    ///Initialize variables
  }
}
