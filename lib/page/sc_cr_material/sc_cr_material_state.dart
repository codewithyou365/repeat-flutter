import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';

class ScCrMaterialState {
  final List<Book> list = <Book>[];
  var loading = false.obs;
  var indexCount = 0.obs;
  var indexTotal = 1.obs;
  var contentProgress = 0.0.obs;
  var skipSsl = false;
}
