import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class CopyTemplate {
  String prefix;
  String suffix;

  CopyTemplate(this.prefix, this.suffix);

  String toStringWithText(String text) {
    return '$prefix$text$suffix'.trim();
  }

  factory CopyTemplate.fromJson(Map<String, dynamic> json) {
    return CopyTemplate(json['prefix'], json['suffix']);
  }

  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'suffix': suffix,
    };
  }
}

class CopyLogic<T extends GetxController> {
  static const String id = "CopyLogic";

  List<CopyTemplate> copyTemplates = [];
  final CrK key;
  final T parentLogic;

  CopyLogic(this.key, this.parentLogic);

  Future<void> init() async {
    copyTemplates = await readList();
  }

  String read(int index) {
    return const JsonEncoder.withIndent(' ').convert(copyTemplates[index].toJson());
  }

  Future<bool> write(int index, String json) async {
    try {
      Map<String, dynamic> jsonMap = jsonDecode(json);
      var ct = CopyTemplate.fromJson(jsonMap);
      copyTemplates[index] = ct;
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
    copyTemplates.add(CopyTemplate(ct.prefix, ct.suffix));
    await writeList(copyTemplates);
    parentLogic.update([CopyLogic.id]);
  }

  delete(int index) async {
    copyTemplates.removeAt(index);
    await writeList(copyTemplates);
    parentLogic.update([CopyLogic.id]);
  }

  Future<List<CopyTemplate>> readList() async {
    String? json = await Db().db.scheduleDao.stringKv(Classroom.curr, this.key);
    if (json == null) {
      return [];
    }
    List<dynamic> jsonList = jsonDecode(json);
    return jsonList.map((item) => CopyTemplate.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> writeList(List<CopyTemplate> list) async {
    List<Map<String, dynamic>> jsonList = list.map((template) => template.toJson()).toList();
    var str = jsonEncode(jsonList);
    await Db().db.scheduleDao.insertKv(CrKv(Classroom.curr, this.key, str));
  }

  List<String> toShowText(String text) {
    List<String> ret = [];
    for (var value in copyTemplates) {
      ret.add(value.toStringWithText(text));
    }
    return ret;
  }

  bool show(BuildContext context, List<String> list, {bool isList = false}) {
    final Size screenSize = MediaQuery.of(context).size;
    if (copyTemplates.isEmpty) {
      copyTemplates.add(CopyTemplate("prefix\n", "\nsuffix"));
    }
    if (list.isEmpty) {
      return false;
    }
    String text = list[0];
    if (isList) {
      for (int i = 0; i < list.length; i++) {
        if (i == 0) {
          text = "${i + 1}. ${list[i]}";
        } else {
          text += "\n${i + 1}. ${list[i]}";
        }
      }
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          width: screenSize.width,
          height: screenSize.height / 2,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 20.0),
            child: GetBuilder<T>(
              id: CopyLogic.id,
              builder: (_) {
                final copyText = toShowText(text);
                final showText = toShowText(StringUtil.limit(text, 255));
                return ListView(
                  children: [
                    ...List.generate(
                      showText.length,
                      (index) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Card(
                          child: PopupMenuButton<String>(
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
                                  var value = RxString(read(index));
                                  MsgBox.strInputWithYesOrNo(
                                    value,
                                    I18nKey.labelDetailConfig.tr,
                                    minLines: 5,
                                    maxLines: 15,
                                    null,
                                    yes: () {
                                      write(index, value.value);
                                    },
                                    yesBtnTitle: I18nKey.btnSave.tr,
                                    no: () {
                                      Get.back();
                                      MsgBox.noWithQrCode(I18nKey.btnShare.tr, value.value, null);
                                    },
                                    noBtnTitle: I18nKey.btnShare.tr,
                                    barrierDismissible: true,
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
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    return true;
  }
}
