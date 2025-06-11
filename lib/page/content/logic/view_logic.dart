import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';

abstract class ViewLogic {
  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  final void Function(List<String> selected) onCardTapDown;

  ViewLogic({
    required VoidCallback onSearchUnfocus,
    required this.onCardTapDown,
  }) {
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
