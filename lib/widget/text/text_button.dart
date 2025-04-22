import 'package:flutter/material.dart';

class MyTextButton {
  static Widget build(VoidCallback? callback, String text, [TextStyle? style]) {
    return TextButton(
      onPressed: callback,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
