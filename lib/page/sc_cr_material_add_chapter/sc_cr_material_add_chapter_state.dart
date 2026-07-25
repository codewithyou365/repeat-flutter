import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';

class ScCrMaterialAddChapterState {
  Book book = Book.empty();

  final TextEditingController mediaController = TextEditingController();
  final TextEditingController srtController = TextEditingController();

  /// The raw text of each input. It is either a local file path or a url,
  /// each one is resolved independently, so they can be mixed.
  RxString mediaSource = "".obs;
  RxString srtSource = "".obs;

  RxBool importing = false.obs;
  RxInt indexCount = 0.obs;
  RxInt indexTotal = 1.obs;
  RxDouble contentProgress = 0.0.obs;
}
