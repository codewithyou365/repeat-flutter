import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/text_diff.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

/// 练习内容跟标准答案的对比：四个"忽略"开关按课堂持久化，开关一动弹窗立刻重算。
class PracticeCheck {
  final RxBool ignoreSpace = true.obs;
  final RxBool ignorePunctuation = true.obs;
  final RxBool ignoreCase = true.obs;
  final RxBool ignoreNumber = false.obs;

  TextDiffOptions get options => TextDiffOptions(
    ignoreSpace: ignoreSpace.value,
    ignorePunctuation: ignorePunctuation.value,
    ignoreCase: ignoreCase.value,
    ignoreNumber: ignoreNumber.value,
  );

  Future<void> load() async {
    ignoreSpace.value = await _read(CrK.practiceIgnoreSpace, true);
    ignorePunctuation.value = await _read(CrK.practiceIgnorePunctuation, true);
    ignoreCase.value = await _read(CrK.practiceIgnoreCase, true);
    ignoreNumber.value = await _read(CrK.practiceIgnoreNumber, false);
  }

  Future<bool> _read(CrK k, bool defaultValue) async {
    final v = await Db().db.crKvDao.getInt(Classroom.curr, k);
    if (v == null) {
      return defaultValue;
    }
    return v == 1;
  }

  Future<void> _set(CrK k, RxBool rx, bool value) async {
    rx.value = value;
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, k, value ? '1' : '0'));
  }

  Future<void> open(
    BuildContext context, {
    required String expected,
    required String actual,
    double? fontSize,
    String? fontFamily,
  }) async {
    final style = TextStyle(fontSize: fontSize ?? 17, fontFamily: fontFamily);
    await Sheet.showBottomSheet(
      context,
      Obx(() {
        // 读一遍四个开关，开关一变这里就重建、重算。
        final result = TextDiff.compare(expected, actual, options);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summary(result),
            const Divider(height: 16),
            Expanded(child: _section(I18nKey.practiceCheckExpected.tr, result.expected, Colors.green, style)),
            const Divider(height: 16),
            Expanded(child: _section(I18nKey.practiceCheckActual.tr, result.actual, Colors.red, style)),
          ],
        );
      }),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          SizedBox(
            height: RowWidget.rowHeight,
            child: Row(
              children: [
                Text(
                  I18nKey.practiceCheckTitle.tr,
                  style: const TextStyle(fontSize: RowWidget.titleFontSize),
                ),
                const Spacer(),
                _settingsMenu(),
              ],
            ),
          ),
          RowWidget.buildDivider(),
        ],
      ),
    );
  }

  Widget _settingsMenu() {
    return PopupMenuButton<void>(
      icon: const Icon(Icons.settings, size: 22),
      tooltip: I18nKey.practiceCheckTitle.tr,
      itemBuilder: (_) => [
        // enabled: false 只是让点开关不会顺手关掉菜单（开关本身照常能点），
        // 代价是文字会被置灰，所以这里把正文色补回来。
        PopupMenuItem<void>(
          enabled: false,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: Theme.of(Get.context!).textTheme.bodyMedium?.color),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RowWidget.buildSwitch(
                  title: I18nKey.ignoreSpace.tr,
                  value: ignoreSpace,
                  set: (v) => _set(CrK.practiceIgnoreSpace, ignoreSpace, v),
                ),
                RowWidget.buildSwitch(
                  title: I18nKey.ignorePunctuation.tr,
                  value: ignorePunctuation,
                  set: (v) => _set(CrK.practiceIgnorePunctuation, ignorePunctuation, v),
                ),
                RowWidget.buildSwitch(
                  title: I18nKey.ignoreCase.tr,
                  value: ignoreCase,
                  set: (v) => _set(CrK.practiceIgnoreCase, ignoreCase, v),
                ),
                RowWidget.buildSwitch(
                  title: I18nKey.ignoreNumber.tr,
                  value: ignoreNumber,
                  set: (v) => _set(CrK.practiceIgnoreNumber, ignoreNumber, v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary(TextDiffResult result) {
    final color = result.same ? Colors.green : Colors.red;
    return Row(
      children: [
        Icon(result.same ? Icons.check_circle : Icons.cancel, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          result.same ? I18nKey.practiceCheckSame.tr : I18nKey.practiceCheckDiff.trArgs(['${result.diffCount}']),
          style: TextStyle(fontSize: 15, color: color),
        ),
      ],
    );
  }

  Widget _section(String title, List<DiffSpan> spans, Color diffColor, TextStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Expanded(
          child: SingleChildScrollView(
            child: SelectionArea(
              child: Text.rich(
                TextSpan(
                  children: [
                    for (final span in spans)
                      TextSpan(
                        text: span.text,
                        style: span.mark == DiffMark.diff ? style.copyWith(color: diffColor, backgroundColor: diffColor.withAlpha(40)) : style,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
