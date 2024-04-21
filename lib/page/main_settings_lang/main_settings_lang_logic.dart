import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_translations.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:repeat_flutter/main.dart';

import 'main_settings_lang_state.dart';

class MainSettingsLangLogic extends GetxController {
  final MainSettingsLangState state = MainSettingsLangState();

  set(I18nLocal lang) {
    var myAppLogic = Get.find<MyAppLogic>();
    myAppLogic.i18nLocal.value = lang;
    var kv = Kv(SettingsConstant.settingsI18n.name, myAppLogic.i18nLocal.value.name);
    Db().db.kvDao.insertKv(kv);
    Get.updateLocale(lang.locale);
  }
}
