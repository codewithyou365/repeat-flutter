import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/ip.dart';

import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/logic/widget/user_manager.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class WebManager<T extends GetxController> {
  static const String bodyId = "WebManager.bodyId";
  static const String detailSearchId = "WebManager.searchId";
  final T parentLogic;

  late UserManager userManager = UserManager<T>(parentLogic);
  late VoidCallback onOpenWeb;
  bool openPending = false;
  WebServer web = WebServer();
  RxBool open = RxBool(false);
  RxString online = RxString("");
  List<String> urls = [];
  RxBool ignoringPunctuation = RxBool(false);
  RxBool editInGame = RxBool(false);
  RxInt matchType = RxInt(MatchType.all.index);
  RxString skipChar = RxString("");

  WebManager(this.parentLogic);

  String get title {
    return "${I18nKey.web.tr}(${open.value})";
  }

  String getOnline() {
    return "${web.server.nodes.userId2Node.length} / ${userManager.allowRegisterNumber}";
  }

  Future<void> init(VoidCallback onOpenWeb) async {
    this.onOpenWeb = onOpenWeb;
    await userManager.init();
  }

  void setIgnoringPunctuation(bool ignoringPunctuation) {
    this.ignoringPunctuation.value = ignoringPunctuation;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ignoringPunctuationInTypingGame, ignoringPunctuation ? '1' : '0'));
  }

  void switchWeb(bool value) async {
    if (openPending) {
      return;
    }
    openPending = true;
    try {
      if (open.value == value) {
        return;
      }
      if (value) {
        try {
          int gamePort = await web.start();
          this.urls = [];
          var ips = await Ip.getLanIps();
          for (var i = 0; i < ips.length; i++) {
            String url = ips[i];
            this.urls.add('http://$url:$gamePort');
          }
          onOpenWeb();
        } catch (e) {
          Snackbar.show('Error Start Web: $e');
          return;
        }
      } else {
        try {
          await web.stop();
          this.urls = [];
        } catch (e) {
          Snackbar.show('Error Stop Web: $e');
          return;
        }
      }
    } finally {
      openPending = false;
      open.value = value;
    }
  }

  void setMatchType(int matchType) {
    this.matchType.value = matchType;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.matchTypeInTypingGame, '$matchType'));
  }

  void setSkipChar(String skipChar) {
    if (skipChar.isNotEmpty) {
      this.skipChar.value = skipChar[0];
    } else {
      this.skipChar.value = '';
    }
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.skipCharacterInTypingGame, skipChar));
  }

  Future<void> showSheet({
    bool focus = true,
    String? id = "",
  }) async {
    var ki = await Db().db.crKvDao.getInt(Classroom.curr, CrK.ignoringPunctuationInTypingGame);
    if (ki != null) {
      ignoringPunctuation.value = ki == 1;
    }
    ki = await Db().db.crKvDao.getInt(Classroom.curr, CrK.matchTypeInTypingGame);
    if (ki != null) {
      matchType.value = ki;
    }
    var ks = await Db().db.crKvDao.getString(Classroom.curr, CrK.skipCharacterInTypingGame);
    if (ks != null) {
      skipChar.value = ks;
    }
    online.value = getOnline();

    return Sheet.withHeaderAndBody(
      Get.context!,
      Padding(
        key: GlobalKey(),
        padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 0.0),
        child: Column(
          children: [
            RowWidget.buildSwitch(
              I18nKey.web.tr,
              open,
              switchWeb,
            ),
            RowWidget.buildDivider(),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 0.0),
        child: ListView(
          children: [
            Obx(() {
              return Column(
                children: [
                  ...List.generate(
                    open.value ? urls.length : 0,
                    (index) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Card(
                        color: Theme.of(Get.context!).secondaryHeaderColor,
                        child: InkWell(
                          onTap: () => {
                            MsgBox.noWithQrCode(
                              I18nKey.labelLanAddress.tr,
                              urls[index],
                              urls[index],
                            ),
                          },
                          child: ListTile(
                            title: Text('${I18nKey.labelLanAddress.tr}-${index + 1}'),
                            subtitle: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Text(urls[index]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            Obx(() {
              return RowWidget.buildTextWithEdit(
                I18nKey.labelOnlineUserNumber.tr,
                online,
                onTap: () async {
                  await userManager.show(Get.context!);
                  online.value = getOnline();
                },
              );
            }),
            RowWidget.buildDividerWithoutColor(),
            RowWidget.buildCupertinoPicker(
              I18nKey.labelGameRuleSettings.tr,
              [I18nKey.labelWordGuessGame.tr],
              RxInt(0),
              pickWidth: 150,
            ),
            RowWidget.buildDividerWithoutColor(),
            RowWidget.buildSwitch(
              I18nKey.labelIgnorePunctuation.tr,
              ignoringPunctuation,
              setIgnoringPunctuation,
            ),
            RowWidget.buildDividerWithoutColor(),
            Obx(() {
              return RowWidget.buildCupertinoPicker(
                I18nKey.labelMatchType.tr,
                [I18nKey.labelWord.tr, I18nKey.labelSingle.tr, I18nKey.labelAll.tr],
                matchType,
                changed: setMatchType,
              );
            }),
            RowWidget.buildDividerWithoutColor(),
            Obx(() {
              return RowWidget.buildTextWithEdit(
                I18nKey.labelSkipCharacter.tr,
                skipChar,
                yes: () {
                  Get.back();
                  setSkipChar(skipChar.value);
                },
              );
            }),
            RowWidget.buildDividerWithoutColor(),
          ],
        ),
      ),
      rate: 1,
    ).then((_) {
      // searchController.dispose();
      // focusNode.dispose();
    });
  }
}
