import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';

abstract class ViewLogic {
  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();


  ViewLogic({
    required VoidCallback onSearchUnfocus,
  }) {
    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus) {
        onSearchUnfocus();
      }
    });
  }

  Widget show({required double height, required double width, bool focus = true});

  /// 重新按当前筛选条件取列表骨架。是 async 的 —— 过滤和排序都下推 SQL 了，
  /// 不再是对一份常驻内存的全量列表做 where。
  Future<void> trySearch({bool force = false});

  void dispose();
}
