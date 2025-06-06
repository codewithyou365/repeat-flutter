import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';

abstract class ViewLogic {
  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  ViewLogic({required VoidCallback onSearchUnfocus}) {
    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus) {
        onSearchUnfocus();
      }
    });
  }

  Widget show({required double height, required double width, bool focus = true});

  void trySearch({bool force = false});

  dispose();
}
