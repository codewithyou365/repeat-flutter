import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

class Select {
  static void showSheetWithoutAutoHide({
    required String title,
    required List<String> keys,
    autoHeight = true,
    required void Function(int index) callback,
  }) {
    showSheet(
      title: title,
      keys: keys,
      autoHeight: autoHeight,
      autoHide: false,
      callback: callback,
    );
  }

  static Future<int?> showSheet({
    required String title,
    required List<String> keys,
    autoHeight = true,
    autoHide = true,
    void Function(int index)? callback,
  }) async {
    double? height;
    if (autoHeight) {
      height = (keys.length + 1) * (RowWidget.rowHeight + RowWidget.dividerHeight);
    }
    int? ret;
    await Sheet.withHeaderAndBody(
      Get.context!,
      Column(
        key: GlobalKey(),
        mainAxisSize: MainAxisSize.min,
        children: [
          RowWidget.buildMiddleText(title),
          RowWidget.buildDividerWithoutColor(),
        ],
      ),
      ListView(
        children: List.generate(keys.length, (index) => index).expand((index) {
          final widgets = <Widget>[
            RowWidget.buildSelect(
              title: keys[index],
              onTap: () {
                ret = index;
                if (callback != null) {
                  callback(index);
                }
                if (autoHide) Get.back();
              },
            ),
          ];
          if (index != keys.length - 1) {
            widgets.add(RowWidget.buildDividerWithoutColor());
          }
          return widgets;
        }).toList(),
      ),
      height: height,
    );
    return ret;
  }
}
