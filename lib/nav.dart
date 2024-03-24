import 'package:get/get.dart';
import 'package:repeat_flutter/page/main/main_binding.dart';
import 'package:repeat_flutter/page/main/main_view.dart';
import 'package:repeat_flutter/page/main_settings/main_settings_view.dart';
import 'package:repeat_flutter/page/main_settings_lang/main_settings_lang_binding.dart';
import 'package:repeat_flutter/page/main_settings_lang/main_settings_lang_view.dart';
import 'package:repeat_flutter/page/main_settings_theme/main_settings_theme_binding.dart';
import 'package:repeat_flutter/page/main_settings_theme/main_settings_theme_view.dart';


enum Nav {
  main,
  mainSettings,
  mainSettingsLang,
  mainSettingsTheme,
  ;


  Future? push() {
    return Get.toNamed(toPath());
  }

  Future? pop() {
    return Get.offNamed(toPath());
  }

  static back() {
    Get.back();
  }

  String toPath() {
    if (!pathCache.containsKey(this)) {
      List<String> words = name.split(RegExp(r"(?=[A-Z])"));
      pathCache[this] = '/${words.join('/').toLowerCase()}';
    }
    return pathCache[this]!;
  }

  static Map<Nav, String> pathCache = {};
  static final String initialRoute = main.toPath();

  static final List<GetPage> getPages = [
    GetPage(
        name: main.toPath(),
        page: () => MainPage(),
        binding: MainBinding()
    ),
    GetPage(
      name: mainSettings.toPath(),
      transition: Transition.rightToLeft,
      page: () => MainSettingsPage(),
    ),
    GetPage(
        name: mainSettingsLang.toPath(),
        transition: Transition.rightToLeft,
        page: () => MainSettingsLangPage(),
        binding: MainSettingsLangBinding()
    ),
    GetPage(
        name: mainSettingsTheme.toPath(),
        transition: Transition.rightToLeft,
        page: () => MainSettingsThemePage(),
        binding: MainSettingsThemeBinding()
    ),
  ];
}
