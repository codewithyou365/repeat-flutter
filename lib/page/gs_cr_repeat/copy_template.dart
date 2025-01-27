import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

class CopyTemplate {
  String prefix;
  String suffix;

  CopyTemplate(this.prefix, this.suffix);

  String toStringWithText(String text) {
    return '$prefix\n$text\n$suffix';
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

class CopyLogic {
  List<CopyTemplate> copyTemplates = [];

  Future<void> init() async {
    var copyTemplateStr = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.copyTemplate);

    copyTemplates.add(CopyTemplate("asdfasfasdf asdflaksdfjalskdjfa sdfalsdkjfalsdk f", " "));
    copyTemplates.add(CopyTemplate("xxx,xxx,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxyyyyyyyyyynxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxyyyyyyyyyyxxxxxxx\nxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxyyyyyyyyyynxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxyyyyyyyyyy", " "));
    return;
  }

  List<String> toShowText(String text) {
    List<String> ret = [];
    for (var value in copyTemplates) {
      ret.add(value.toStringWithText(text));
    }
    return ret;
  }

  void show(BuildContext context, String text) {
    final showText = toShowText(text);
    final Size screenSize = MediaQuery.of(context).size;
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
            child: ListView(
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
                            onTap: () {},
                            child: Text(I18nKey.labelCopyText.tr),
                          ),
                          PopupMenuItem<String>(
                            onTap: () {
                              var value = RxString("");
                              MsgBox.strInputWithYesOrNo(
                                value,
                                I18nKey.labelDetailConfig.tr,
                                minLines: 5,
                                maxLines: 15,
                                null,
                                yes: () {},
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
                            onTap: () {},
                            child: Text(I18nKey.labelCopyConfig.tr),
                          ),
                          PopupMenuItem<String>(
                            onTap: () {},
                            child: Text(I18nKey.labelDeleteConfig.tr),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
