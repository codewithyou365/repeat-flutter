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

extension I18nLocalFromString on I18nLocal {
  static I18nLocal c(String value) {
    return I18nLocal.values.firstWhere(
      (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase(),
      orElse: () => I18nLocal.en,
    );
  }
}

final ConfigEn configEn = ConfigEn();

class I18nTranslations extends Translations {
  static final Map<String, Map<String, String>> data = {I18nLocal.en.name: configEn.data, I18nLocal.zh.name: ConfigZh(defaultData: configEn.data).data};

  @override
  Map<String, Map<String, String>> get keys => data;
}
