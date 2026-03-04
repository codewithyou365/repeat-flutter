import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:mustache_template/mustache_template.dart';

enum TextTemplateMode {
  copy,
  get,
  edit,
}

class TextTemplate<T extends GetxController> {
  static const String id = "TextTemplate";
  static const String defaultStringTemplate = "{{text}}";
  static const String defaultVerseTemplate = '''
{{#verses}}
q{{index1}}: {{question}}
a{{index1}}: {{answer}}
{{/verses}}
  ''';
  List<String> copyTemplates = [];
  final CrK key;
  final T parentLogic;
  final GlobalKey topColumn = GlobalKey();
  double listViewHeight = 50;

  TextTemplate(this.key, this.parentLogic);

  Future<void> init() async {
    copyTemplates = await readList(key);
  }

  String read(int index) {
    if (index < copyTemplates.length) {
      return copyTemplates[index];
    } else {
      return defaultStringTemplate;
    }
  }

  Future<bool> write(int index, String json) async {
    try {
      copyTemplates[index] = json;
    } catch (e) {
      MsgBox.yes(I18nKey.labelTips.tr, I18nKey.labelJsonErrorSaveFailed.tr);
      return false;
    }
    await writeList(copyTemplates);
    parentLogic.update([TextTemplate.id]);
    Get.back();
    return true;
  }

  copy(int index) async {
    final ct = copyTemplates[index];
    copyTemplates.add(ct);
    await writeList(copyTemplates);
    parentLogic.update([TextTemplate.id]);
  }

  delete(int index) async {
    copyTemplates.removeAt(index);
    await writeList(copyTemplates);
    parentLogic.update([TextTemplate.id]);
  }

  static Future<List<String>> readList(CrK key) async {
    String? json = await Db().db.crKvDao.getStr(Classroom.curr, key);
    if (json == null) {
      return [];
    }
    return ListUtil.toList(json);
  }

  Future<void> writeList(List<String> list) async {
    var str = jsonEncode(list);
    await Db().db.scheduleDao.insertKv(CrKv(Classroom.curr, this.key, str));
  }

  List<String> getShowVerses(List<VerseShow> verses) {
    List<String> ret = [];
    for (var templateString in copyTemplates) {
      final template = Template(templateString, htmlEscapeValues: false);
      final rendered = template.renderString({
        'verses': verses.asMap().entries.map((e) {
          var m = jsonDecode(e.value.verseContent);
          return {
            'index0': e.key,
            'index1': e.key + 1,
            'indexA': Num.toBase26(e.key),
            'question': m['q'] ?? '',
            'answer': m['a'] ?? '',
          };
        }).toList(),
      });
      ret.add(rendered.toString());
    }
    return ret;
  }

  List<String> getShowText(String text) {
    List<String> ret = [];
    for (var templateString in copyTemplates) {
      final template = Template(templateString, htmlEscapeValues: false);
      final rendered = template.renderString({'text': text});
      ret.add(rendered.toString());
    }
    return ret;
  }

  Future<String> show(TextTemplateMode mode, BuildContext context, Object data) async {
    if (copyTemplates.isEmpty) {
      if (data is String) {
        copyTemplates.add(defaultStringTemplate);
      } else {
        copyTemplates.add(defaultVerseTemplate);
      }
    }
    RxString getV = RxString('');
    await Sheet.showBottomSheet(
      context,
      head: SheetHead(
        widgets: [
          GetBuilder<T>(
            id: TextTemplate.id,
            builder: (_) {
              return RowWidget.buildText(I18nKey.labelCopyTemplateCount.tr, '${copyTemplates.length}');
            },
          ),
          RowWidget.buildDivider(),
        ],
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
      ),
      GetBuilder<T>(
        id: TextTemplate.id,
        builder: (_) {
          List<String> copyStrings = (data is String) ? getShowText(data) : getShowVerses(data as List<VerseShow>);
          return ListView.builder(
            shrinkWrap: true,
            itemCount: copyStrings.length,
            itemBuilder: (context, index) {
              final fullText = copyStrings[index];
              final previewText = StringUtil.limit(fullText, 255);

              return RowWidget.buildCard(
                _buildActionWidget(mode, index, fullText, previewText, getV),
              );
            },
          );
        },
      ),
    );
    return getV.value;
  }

  Widget _buildActionWidget(TextTemplateMode mode, int index, String fullText, String previewText, RxString getV) {
    Widget content = Padding(
      padding: EdgeInsets.all(12.w),
      child: Text(previewText),
    );

    switch (mode) {
      case TextTemplateMode.get:
        return InkWell(
          onTap: () {
            getV.value = fullText;
            Get.back();
          },
          child: content,
        );

      case TextTemplateMode.copy:
        return InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: fullText));
            Snackbar.show(I18nKey.labelCopiedToClipboard.tr);
            getV.value = fullText;
          },
          child: content,
        );

      default:
        return PopupMenuButton<int>(
          child: content,
          onSelected: (value) async {
            if (value == 0) {
              getV.value = fullText;
              Clipboard.setData(ClipboardData(text: fullText));
              Snackbar.show(I18nKey.labelCopiedToClipboard.tr);
            } else if (value == 1) {
              Nav.editor.push(
                arguments: EditorArgs(
                  title: I18nKey.labelDetailConfig.tr,
                  value: read(index),
                  save: (str) => write(index, str),
                ),
              );
            } else if (value == 2) {
              copy(index);
            } else if (value == 3) {
              delete(index);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 0, child: Text(I18nKey.labelCopyText.tr)),
            PopupMenuItem(value: 1, child: Text(I18nKey.labelDetailConfig.tr)),
            PopupMenuItem(value: 2, child: Text(I18nKey.labelCopyConfig.tr)),
            PopupMenuItem(value: 3, child: Text(I18nKey.labelDeleteConfig.tr)),
          ],
        );
    }
  }

  bool showQaList(BuildContext context, List<VerseShow> list) {
    if (list.isEmpty) {
      return false;
    }
    show(TextTemplateMode.edit, context, list);
    return true;
  }
}
