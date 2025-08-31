import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';

import 'book_editor_args.dart';

class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class BookEditorState {
  final List<Address> addresses = <Address>[];
  late BookEditorArgs args;
  var lanAddressSuffix = "/index.html";
  RxBool webStart = false.obs;
  RxString user = "".obs;
  RxString password = "".obs;
}
