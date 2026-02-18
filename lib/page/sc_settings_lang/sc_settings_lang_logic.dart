import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_translations.dart';
import 'package:repeat_flutter/main.dart';

import 'sc_settings_lang_state.dart';

class ScSettingsLangLogic extends GetxController {
  final ScSettingsLangState state = ScSettingsLangState();

  set(I18nLocal lang) {
    var myAppLogic = Get.find<MyAppLogic>();
    myAppLogic.i18nLocal.value = lang;
    var kv = Kv(K.settingsI18n, myAppLogic.i18nLocal.value.name);
    Db().db.kvDao.insertOrReplace(kv);
    Get.updateLocale(lang.locale);
  }
}
