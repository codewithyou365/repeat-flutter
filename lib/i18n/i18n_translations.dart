library i18n;

import 'dart:ui';

import 'package:get/get.dart';

import 'config_en.dart';
import 'config_zh.dart';

enum I18nLocal { en, zh }

extension I18nLocalExtension on I18nLocal {
  Locale get locale {
    switch (this) {
      case I18nLocal.en:
        return const Locale('en', 'US');
      case I18nLocal.zh:
        return const Locale('zh', 'CN');
    }
  }
}

class I18nTranslations extends Translations {
  final ConfigEn configEn = ConfigEn();

  @override
  Map<String, Map<String, String>> get keys =>
      {
        I18nLocal.en.name: configEn.data,
        I18nLocal.zh.name: ConfigZh(defaultData: configEn.data).data
      };
}
