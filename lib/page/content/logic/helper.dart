import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

class Helper {
  static TextField getTextField({
    TextEditingController? controller,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      style: const TextStyle(fontSize: 20),
      controller: controller,
      focusNode: focusNode,
      textAlignVertical: TextAlignVertical.center,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: I18nKey.labelSearch.tr,
        isCollapsed: true,
        border: InputBorder.none,
      ),
    );
  }
}
