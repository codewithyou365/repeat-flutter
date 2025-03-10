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
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:mustache_template/mustache_template.dart';

import 'editor.dart';

class CopyLogic<T extends GetxController> {
  static const String id = "CopyLogic";

  List<String> copyTemplates = [];
  final CrK key;
  final T parentLogic;
  final GlobalKey topColumn = GlobalKey();
  double listViewHeight = 50;

  CopyLogic(this.key, this.parentLogic);

  Future<void> init() async {
    copyTemplates = await readList();
  }

  String read(int index) {
    return copyTemplates[index];
  }

  Future<bool> write(int index, String json) async {
    try {
      copyTemplates[index] = json;
    } catch (e) {
      MsgBox.yes(I18nKey.labelTips.tr, I18nKey.labelJsonErrorSaveFailed.tr);
      return false;
    }
    await writeList(copyTemplates);
    parentLogic.update([CopyLogic.id]);
    Get.back();
    return true;
  }

  copy(int index) async {
    final ct = copyTemplates[index];
    copyTemplates.add(ct);
    await writeList(copyTemplates);
    parentLogic.update([CopyLogic.id]);
  }

  delete(int index) async {
    copyTemplates.removeAt(index);
    await writeList(copyTemplates);
    parentLogic.update([CopyLogic.id]);
  }

  Future<List<String>> readList() async {
    String? json = await Db().db.scheduleDao.stringKv(Classroom.curr, this.key);
    if (json == null) {
      return [];
    }
    return ListUtil.toList(json);
  }

  Future<void> writeList(List<String> list) async {
    var str = jsonEncode(list);
    await Db().db.scheduleDao.insertKv(CrKv(Classroom.curr, this.key, str));
  }

  List<String> getShowSegments(List<SegmentContent> segments) {
    List<String> ret = [];
    for (var templateString in copyTemplates) {
      final template = Template(templateString);
      final rendered = template.renderString({
        'segments': segments
            .asMap()
            .entries
            .map((e) => {
                  'index0': e.key,
                  'index1': e.key + 1,
                  'indexA': Num.toBase26(e.key),
                  'question': e.value.question,
                  'answer': e.value.answer,
                })
            .toList()
      });
      ret.add(rendered.toString());
    }
    return ret;
  }

  List<String> getShowText(String text) {
    List<String> ret = [];
    for (var templateString in copyTemplates) {
      final template = Template(templateString);
      final rendered = template.renderString({'text': text});
      ret.add(rendered.toString());
    }
    return ret;
  }

  void show(BuildContext context, String defaultTemplate, Object data) {
    if (copyTemplates.isEmpty) {
      copyTemplates.add(defaultTemplate);
    }

    Sheet.withHeaderAndBody(
      context,
      [
        GetBuilder<T>(
          id: CopyLogic.id,
          builder: (_) {
            return RowWidget.buildText(I18nKey.labelCopyTemplateCount.tr, '${copyTemplates.length}');
          },
        ),
        RowWidget.buildDivider(),
      ],
      GetBuilder<T>(
        id: CopyLogic.id,
        builder: (_) {
          List<String> copyText = [];
          if (data is String) {
            copyText = getShowText(data);
          } else {
            copyText = getShowSegments(data as List<SegmentContent>);
          }
          List<String> showText = [];
          for (var v in copyText) {
            showText.add(StringUtil.limit(v, 255));
          }
          return ListView(children: [
            ...List.generate(
              showText.length,
              (index) => RowWidget.buildCard(
                PopupMenuButton<String>(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Text(showText[index]),
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: copyText[index]));
                        Snackbar.show(I18nKey.labelCopiedToClipboard.tr);
                      },
                      child: Text(I18nKey.labelCopyText.tr),
                    ),
                    PopupMenuItem<String>(
                      onTap: () {
                        Editor.show(
                          Get.context!,
                          I18nKey.labelDetailConfig.tr,
                          read(index),
                          (str) async {
                            write(index, str);
                          },
                          qrPagePath: Nav.gsCrContentScan.path,
                        );
                      },
                      child: Text(I18nKey.labelDetailConfig.tr),
                    ),
                    PopupMenuItem<String>(
                      onTap: () {
                        copy(index);
                      },
                      child: Text(I18nKey.labelCopyConfig.tr),
                    ),
                    PopupMenuItem<String>(
                      onTap: () {
                        delete(index);
                      },
                      child: Text(I18nKey.labelDeleteConfig.tr),
                    ),
                  ],
                ),
              ),
            )
          ]);
        },
      ),
    );
  }

  bool showQaList(BuildContext context, List<SegmentContent> list) {
    if (list.isEmpty) {
      return false;
    }
    show(
        context,
        '''
{{#segments}}
q{{index1}}: {{question}}
a{{index1}}: {{answer}}
{{/segments}}
  ''',
        list);
    return true;
  }
}
