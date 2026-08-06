import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_logic.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

/// 带参数的自定义动作在执行前弹这个 sheet，让用户依次填模版里用到的那几个参数。
class ExpandInputSheet {
  /// [title] 一般是动作名，[numbers] 是模版里实际用到的参数编号
  /// （见 [ExpandLogic.inputNumbersOf]，比如模版只写了 {{input1}} 和 {{input6}} 就是 [1, 6]，
  /// 只弹这两行）。
  /// 返回按 [numbers] 的顺序排好的参数值；用户没点"确定"（取消/点空白关掉）返回 null，表示这次不执行。
  ///
  /// 每一行用的是 buildTextWithEdit：点了弹的是对话框而不是就地编辑，
  /// 这样输入法不会盖住 sheet 底部的输入框（sheet 自己是固定高度贴在屏幕底部的）。
  static Future<List<String>?> open(String title, List<int> numbers) async {
    final count = numbers.length;
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
            Obx(() => RowWidget.buildTextWithEdit(ExpandLogic.inputKeyOf(numbers[i]), values[i])),
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
