import 'package:get/get.dart';

import 'book_editor_args.dart';

class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class BookEditorState {
  final List<Address> addresses = <Address>[];
  BookEditorArgs args = BookEditorArgs(bookId: 0, chapterIndex: 0, verseIndex: 0);

  int chapterIndex = 0;
  int verseIndex = 0;
  int bookId = 0;

  var lanAddressSuffix = "/index.html";
  RxBool webStart = false.obs;
  RxString user = "".obs;
  RxString password = "".obs;
}
