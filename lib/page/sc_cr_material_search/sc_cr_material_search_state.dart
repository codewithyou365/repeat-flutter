import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';

class ScCrMaterialSearchState {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  /// 正在建立/重建索引
  final RxBool indexing = false.obs;
  final RxInt indexDone = 0.obs;
  final RxInt indexTotal = 1.obs;

  /// 已经搜过一次，用来区分"还没搜"和"搜了没结果"
  final RxBool searched = false.obs;
  final RxList<VerseShow> result = <VerseShow>[].obs;
}
