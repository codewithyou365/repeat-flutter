
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ContentState {
   RxString search = "".obs;
   RxBool startSearch = false.obs;
   RxInt tabIndex = 0.obs;

   late TextEditingController searchController = TextEditingController(text: search.value);
   final focusNode = FocusNode();
}
