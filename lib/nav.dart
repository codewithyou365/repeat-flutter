import 'package:get/get.dart';
import 'package:repeat_flutter/page/main/main_nav.dart';
import 'package:repeat_flutter/page/main_content/main_content_nav.dart';
import 'package:repeat_flutter/page/main_repeat/main_repeat_nav.dart';
import 'package:repeat_flutter/page/main_repeat_finish/main_repeat_finish_nav.dart';
import 'package:repeat_flutter/page/main_settings/main_settings_nav.dart';
import 'package:repeat_flutter/page/main_settings_lang/main_settings_lang_nav.dart';
import 'package:repeat_flutter/page/main_settings_theme/main_settings_theme_nav.dart';
import 'package:repeat_flutter/page/main_stats/main_stats_nav.dart';
import 'package:repeat_flutter/page/main_stats_learn/main_stats_learn_nav.dart';
import 'package:repeat_flutter/page/main_stats_review/main_stats_review_nav.dart';

enum Nav {
  main("/main"),
  mainContent("/main/content"),
  mainRepeat("/main/repeat"),
  mainRepeatFinish("/main/repeat/finish"),
  mainSettings("/main/settings"),
  mainSettingsLang("/main/settings/lang"),
  mainSettingsTheme("/main/settings/theme"),
  mainStats("/main/stats"),
  mainStatsLearn("/main/stats/learn"),
  mainStatsReview("/main/stats/review"),
  ;

  final String path;

  const Nav(this.path);

  Future? push({dynamic arguments}) {
    return Get.toNamed(path, arguments: arguments);
  }

  Future? pop() {
    return Get.offNamed(path);
  }

  static back() {
    Get.back();
  }

  static final String initialRoute = main.path;

  static final List<GetPage> getPages = [
    mainNav(main.path),
    mainContentNav(mainContent.path),
    mainRepeatNav(mainRepeat.path),
    mainRepeatFinishNav(mainRepeatFinish.path),
    mainSettingsNav(mainSettings.path),
    mainSettingsLangNav(mainSettingsLang.path),
    mainSettingsThemeNav(mainSettingsTheme.path),
    mainStatsNav(mainStats.path),
    mainStatsLearnNav(mainStatsLearn.path),
    mainStatsReviewNav(mainStatsReview.path),
  ];
}
