import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'game_settings.dart';

class GameSettingsType extends GameSettings {
  RxBool ignoringPunctuation = RxBool(false);
  RxString skipChar = RxString("");

  @override
  Future<void> onInit() async {
    var ki = await Db().db.crKvDao.getInt(Classroom.curr, CrK.typeGameForIgnoringPunctuation);
    if (ki != null) {
      ignoringPunctuation.value = ki == 1;
    }
    var ks = await Db().db.crKvDao.getString(Classroom.curr, CrK.typeGameForSkipCharacter);
    if (ks != null) {
      skipChar.value = ks;
    }
  }

  @override
  Future<void> onClose() async {}

  void setIgnoringPunctuation(bool ignoringPunctuation) {
    this.ignoringPunctuation.value = ignoringPunctuation;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.typeGameForIgnoringPunctuation, ignoringPunctuation ? '1' : '0'));
  }

  void setSkipChar(String skipChar) {
    if (skipChar.isNotEmpty) {
      this.skipChar.value = skipChar[0];
    } else {
      this.skipChar.value = '';
    }
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.typeGameForSkipCharacter, skipChar));
  }

  @override
  List<Widget> build() {
    return [
      RowWidget.buildSwitch(
        I18nKey.labelIgnorePunctuation.tr,
        ignoringPunctuation,
        setIgnoringPunctuation,
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
