import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RowWidget {
  static const double titleFontSize = 17;
  static const double rowHeight = 50;
  static const double paddingHorizontal = 8;

  static Widget buildMiddleText(String title, {bool main = true}) {
    var ts = const TextStyle(fontSize: titleFontSize);
    if (!main) {
      ts = const TextStyle(fontSize: titleFontSize, color: Colors.grey);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: ts,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: titleFontSize),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSwitch(String title, RxBool value, [Function(bool)? set]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: titleFontSize),
            ),
            const Spacer(),
            Obx(() {
              return Switch(value: value.value, onChanged: set != null ? (v) => set(v) : (v) => {value.value = v});
            }),
          ],
        ),
      ),
    );
  }
}
