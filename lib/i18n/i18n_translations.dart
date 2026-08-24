library i18n;

import 'dart:ui';

import 'package:get/get.dart';

import 'config.dart';
import 'config_de.dart';
import 'config_en.dart';
import 'config_es.dart';
import 'config_fr.dart';
import 'config_id.dart';
import 'config_it.dart';
import 'config_ja.dart';
import 'config_ko.dart';
import 'config_pt.dart';
import 'config_ru.dart';
import 'config_vi.dart';
import 'config_zh.dart';

/// 界面语言。
///
/// 加一门语言只要动这个文件里的三张表（[_locales]、[_names]、[_builders]）加一个
/// config_xx.dart，别处不用改：语言设置页是遍历 [I18nLocal.values] 画出来的。
///
/// 枚举名会被原样存进 Kv(K.settingsI18n)，所以只能往后加，不能改名——
/// 改名会让老用户的设置读不回来（[I18nLocalFromString.c] 找不到就退回 en）。
enum I18nLocal { en, zh, ja, ko, es, fr, de, ru, pt, it, id, vi }

const Map<I18nLocal, Locale> _locales = {
  I18nLocal.en: Locale('en', 'US'),
  I18nLocal.zh: Locale('zh', 'CN'),
  I18nLocal.ja: Locale('ja', 'JP'),
  I18nLocal.ko: Locale('ko', 'KR'),
  I18nLocal.es: Locale('es', 'ES'),
  I18nLocal.fr: Locale('fr', 'FR'),
  I18nLocal.de: Locale('de', 'DE'),
  I18nLocal.ru: Locale('ru', 'RU'),
  I18nLocal.pt: Locale('pt', 'BR'),
  I18nLocal.it: Locale('it', 'IT'),
  I18nLocal.id: Locale('id', 'ID'),
  I18nLocal.vi: Locale('vi', 'VN'),
};

/// 语言名一律写母语写法：选语言的时候用户看不懂当前界面语言，
/// 只能靠认出自己那一行，翻译过来反而找不着。
const Map<I18nLocal, String> _names = {
  I18nLocal.en: 'English',
  I18nLocal.zh: '中文',
  I18nLocal.ja: '日本語',
  I18nLocal.ko: '한국어',
  I18nLocal.es: 'Español',
  I18nLocal.fr: 'Français',
  I18nLocal.de: 'Deutsch',
  I18nLocal.ru: 'Русский',
  I18nLocal.pt: 'Português (BR)',
  I18nLocal.it: 'Italiano',
  I18nLocal.id: 'Bahasa Indonesia',
  I18nLocal.vi: 'Tiếng Việt',
};

/// 各语言的文案表怎么造。统一收 defaultData（英文）兜底：
/// 哪条没译到就退回英文，而不是把 key 名甩到界面上。
final Map<I18nLocal, Config Function(Map<String, String>)> _builders = {
  I18nLocal.zh: (d) => ConfigZh(defaultData: d),
  I18nLocal.ja: (d) => ConfigJa(defaultData: d),
  I18nLocal.ko: (d) => ConfigKo(defaultData: d),
  I18nLocal.es: (d) => ConfigEs(defaultData: d),
  I18nLocal.fr: (d) => ConfigFr(defaultData: d),
  I18nLocal.de: (d) => ConfigDe(defaultData: d),
  I18nLocal.ru: (d) => ConfigRu(defaultData: d),
  I18nLocal.pt: (d) => ConfigPt(defaultData: d),
  I18nLocal.it: (d) => ConfigIt(defaultData: d),
  I18nLocal.id: (d) => ConfigId(defaultData: d),
  I18nLocal.vi: (d) => ConfigVi(defaultData: d),
};

extension I18nLocalExtension on I18nLocal {
  Locale get locale => _locales[this] ?? const Locale('en', 'US');

  /// 语言设置页上那一行显示的名字
  String get displayName => _names[this] ?? name;
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
  // 故意不用 static final 缓存：各 Config 的 put() 调用是在构造函数里执行的，
  // 每次都 new 一份实例、重新跑一遍构造函数，才能让改文案之后热重载(hot reload)立刻生效；
  // 用 static final 的话这份 Map 只在 isolate 生命周期内算一次，热重载不会重新计算。
  static Map<String, Map<String, String>> get data {
    final en = ConfigEn().data;
    return {
      I18nLocal.en.name: en,
      for (final e in _builders.entries) e.key.name: e.value(en).data,
    };
  }

  @override
  Map<String, Map<String, String>> get keys => data;
}
