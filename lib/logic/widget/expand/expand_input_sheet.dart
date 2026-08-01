import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_logic.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

/// 带参数的自定义动作在执行前弹这个 sheet，让用户依次填 input1..inputN。
class ExpandInputSheet {
  /// [title] 一般是动作名，[count] 是参数个数。
  /// 返回按顺序排好的参数值；用户没点"确定"（取消/点空白关掉）返回 null，表示这次不执行。
  ///
  /// 每一行用的是 buildTextWithEdit：点了弹的是对话框而不是就地编辑，
  /// 这样输入法不会盖住 sheet 底部的输入框（sheet 自己是固定高度贴在屏幕底部的）。
  static Future<List<String>?> open(String title, int count) async {
    if (count <= 0) {
      return const <String>[];
    }
    final values = List.generate(count, (_) => ''.obs);
    var confirmed = false;
    await Sheet.showBottomSheet(
      Get.context!,
      ListView(
        shrinkWrap: true,
        children: [
          for (var i = 0; i < count; i++) ...[
            Obx(() => RowWidget.buildTextWithEdit(ExpandLogic.inputKey(i), values[i])),
            RowWidget.buildDividerWithoutColor(),
          ],
          RowWidget.buildButtons([
            Button(I18nKey.btnOk.tr, () {
              confirmed = true;
              Get.back();
            }),
          ]),
        ],
      ),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(title),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 0.6,
    );
    if (!confirmed) {
      return null;
    }
    return values.map((e) => e.value).toList();
  }
}
