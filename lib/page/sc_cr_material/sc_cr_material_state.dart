import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';

class ScCrMaterialState {
  final List<Book> list = <Book>[];
  var loading = false.obs;
}
