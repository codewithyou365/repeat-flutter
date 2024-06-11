import 'package:get/get.dart';
import 'package:repeat_flutter/page/gs/gs_nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_nav.dart';
import 'package:repeat_flutter/page/gs_cr_content/gs_cr_content_nav.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/gs_cr_repeat_nav.dart';
import 'package:repeat_flutter/page/gs_cr_repeat_finish/gs_cr_repeat_finish_nav.dart';
import 'package:repeat_flutter/page/gs_cr_settings/gs_cr_settings_nav.dart';
import 'package:repeat_flutter/page/gs_cr_stats/gs_cr_stats_nav.dart';
import 'package:repeat_flutter/page/gs_cr_stats_learn/gs_cr_stats_learn_nav.dart';
import 'package:repeat_flutter/page/gs_cr_stats_review/gs_cr_stats_review_nav.dart';
import 'package:repeat_flutter/page/gs_settings/gs_settings_nav.dart';
import 'package:repeat_flutter/page/gs_settings_data/gs_settings_data_nav.dart';
import 'package:repeat_flutter/page/gs_settings_lang/gs_settings_lang_nav.dart';
import 'package:repeat_flutter/page/gs_settings_theme/gs_settings_theme_nav.dart';

enum Nav {
  gs("/gs"),
  gsCr("/gs/cr"),
  gsCrContent("/gs/cr/content"),
  gsCrRepeat("/gs/cr/repeat"),
  gsCrRepeatFinish("/gs/cr/repeat/finish"),
  gsCrSettings("/gs/cr/settings"),
  gsCrStats("/gs/cr/stats"),
  gsCrStatsLearn("/gs/cr/stats/learn"),
  gsCrStatsReview("/gs/cr/stats/review"),
  gsSettings("/gs/settings"),
  gsSettingsData("/gs/settings/data"),
  gsSettingsLang("/gs/settings/lang"),
  gsSettingsTheme("/gs/settings/theme"),
  ;

  final String path;

  const Nav(this.path);

  Future? push({dynamic arguments}) {
    return Get.toNamed(path, arguments: arguments);
  }

  void until() {
    Get.until((route) => Get.currentRoute == path);
  }

  static back() {
    Get.back();
  }

  static final String initialRoute = gs.path;

  static final List<GetPage> getPages = [
    gsNav(gs.path),
    gsCrNav(gsCr.path),
    gsCrContentNav(gsCrContent.path),
    gsCrRepeatNav(gsCrRepeat.path),
    gsCrRepeatFinishNav(gsCrRepeatFinish.path),
    gsCrSettingsNav(gsCrSettings.path),
    gsCrStatsNav(gsCrStats.path),
    gsCrStatsLearnNav(gsCrStatsLearn.path),
    gsCrStatsReviewNav(gsCrStatsReview.path),
    gsSettingsNav(gsSettings.path),
    gsSettingsDataNav(gsSettingsData.path),
    gsSettingsLangNav(gsSettingsLang.path),
    gsSettingsThemeNav(gsSettingsTheme.path),
  ];
}
