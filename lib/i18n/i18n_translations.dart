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

class I18nTranslations extends Translations {
  // 故意不用 static final 缓存：ConfigEn/ConfigZh 的 put() 调用是在构造函数里执行的，
  // 每次都 new 一份实例、重新跑一遍构造函数，才能让改文案之后热重载(hot reload)立刻生效；
  // 用 static final 的话这份 Map 只在 isolate 生命周期内算一次，热重载不会重新计算。
  static Map<String, Map<String, String>> get data {
    final configEn = ConfigEn();
    return {
      I18nLocal.en.name: configEn.data,
      I18nLocal.zh.name: ConfigZh(defaultData: configEn.data).data,
    };
  }

  @override
  Map<String, Map<String, String>> get keys => data;
}
