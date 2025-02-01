import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

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

  static Widget buildCupertinoPicker(String title, List<String> options, [ValueChanged<int>? changed]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(paddingHorizontal, 0, 0, 0),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: titleFontSize),
            ),
            const Spacer(),
            SizedBox(
              width: 80.w,
              height: 64,
              child: CupertinoPicker(
                itemExtent: 32.0,
                onSelectedItemChanged: changed,
                children: List.generate(options.length, (index) {
                  return Center(
                      child: Text(
                    options[index],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                  ));
                }),
              ),
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

  static Widget buildDivider() {
    return const Divider(color: Colors.grey);
  }

  static Widget buildTextWithEdit(String title, RxString value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: InkWell(
          onTap: () {
            MsgBox.strInputWithYesOrNo(value, title, "");
          },
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
                  value.value.toString(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
