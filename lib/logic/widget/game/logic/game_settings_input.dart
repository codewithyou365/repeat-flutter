import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'game_settings.dart';

class GameSettingsInput extends GameSettings {
  RxBool ignoringPunctuation = RxBool(false);
  Key matchTypeKey = GlobalKey();
  int matchType = 0;
  RxString skipChar = RxString("");

  @override
  Future<void> onInit(WebServer web) async {
    var ki = await Db().db.crKvDao.getInt(Classroom.curr, CrK.inputGameForIgnoringPunctuation);
    if (ki != null) {
      ignoringPunctuation.value = ki == 1;
    }
    ki = await Db().db.crKvDao.getInt(Classroom.curr, CrK.inputGameForMatchType);
    if (ki != null) {
      matchType = ki;
    } else {
      await setMatchType(MatchType.all.index);
      matchType = MatchType.all.index;
    }
    var ks = await Db().db.crKvDao.getStr(Classroom.curr, CrK.inputGameForSkipCharacter);
    if (ks != null) {
      skipChar.value = ks;
    }
  }

  @override
  Future<void> onWebOpen() async {}

  @override
  Future<void> onWebClose() async {}

  @override
  Future<void> onClose() async {}

  void setIgnoringPunctuation(bool ignoringPunctuation) {
    this.ignoringPunctuation.value = ignoringPunctuation;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.inputGameForIgnoringPunctuation, ignoringPunctuation ? '1' : '0'));
  }

  Future<void> setMatchType(int matchType) async {
    this.matchType = matchType;
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.inputGameForMatchType, '$matchType'));
  }

  void setSkipChar(String skipChar) {
    if (skipChar.isNotEmpty) {
      this.skipChar.value = skipChar[0];
    } else {
      this.skipChar.value = '';
    }
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.inputGameForSkipCharacter, skipChar));
  }

  @override
  List<Widget> build() {
    return [
      RowWidget.buildSwitch(
        title: I18nKey.ignorePunctuation.tr,
        value: ignoringPunctuation,
        disabled: webOpen,
        set: setIgnoringPunctuation,
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildCupertinoPicker(
        key: matchTypeKey,
        title: I18nKey.labelMatchType.tr,
        options: [I18nKey.labelWord.tr, I18nKey.labelSingle.tr, I18nKey.labelAll.tr],
        value: matchType,
        changed: setMatchType,
        disabled: webOpen,
      ),
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
    ];
  }
}
