import 'package:get/get.dart';

import 'book_editor_logic.dart';

class BookEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BookEditorLogic());
  }
}
