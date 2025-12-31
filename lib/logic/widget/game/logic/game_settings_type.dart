import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'game_settings.dart';

class GameSettingsType extends GameSettings {
  RxBool ignorePunctuation = RxBool(false);
  RxBool ignoreCase = RxBool(false);

  @override
  Future<void> onInit(WebServer web) async {
    var kip = await Db().db.crKvDao.getInt(Classroom.curr, CrK.typeGameForIgnorePunctuation);
    if (kip != null) {
      ignorePunctuation.value = kip == 1;
    }
    var kic = await Db().db.crKvDao.getInt(Classroom.curr, CrK.typeGameForIgnoreCase);
    if (kic != null) {
      ignoreCase.value = kic == 1;
    }
  }

  @override
  Future<void> onWebOpen() async {}

  @override
  Future<void> onWebClose() async {}

  @override
  Future<void> onClose() async {}

  void setIgnorePunctuation(bool ignorePunctuation) {
    this.ignorePunctuation.value = ignorePunctuation;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.typeGameForIgnorePunctuation, ignorePunctuation ? '1' : '0'));
  }

  void setIgnoreCase(bool ignoreCase) {
    this.ignoreCase.value = ignoreCase;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.typeGameForIgnoreCase, ignoreCase ? '1' : '0'));
  }

  @override
  List<Widget> build() {
    return [
      RowWidget.buildSwitch(
        I18nKey.ignorePunctuation.tr,
        ignorePunctuation,
        setIgnorePunctuation,
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildSwitch(
        I18nKey.ignoreCase.tr,
        ignoreCase,
        setIgnoreCase,
      ),
    ];
  }
}
