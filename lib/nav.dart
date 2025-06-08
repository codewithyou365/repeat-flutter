import 'package:get/get.dart';
import 'package:repeat_flutter/page/content/content_nav.dart';
import 'package:repeat_flutter/page/gs/gs_nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_nav.dart';
import 'package:repeat_flutter/page/gs_cr_content_scan/gs_cr_content_scan_nav.dart';
import 'package:repeat_flutter/page/gs_cr_content_share/gs_cr_content_share_nav.dart';
import 'package:repeat_flutter/page/gs_cr_content_template/gs_cr_content_template_nav.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/gs_cr_repeat_nav.dart';
import 'package:repeat_flutter/page/gs_cr_settings/gs_cr_settings_nav.dart';
import 'package:repeat_flutter/page/gs_cr_settings_el/gs_cr_settings_el_nav.dart';
import 'package:repeat_flutter/page/gs_cr_settings_rel/gs_cr_settings_rel_nav.dart';
import 'package:repeat_flutter/page/gs_cr_stats/gs_cr_stats_nav.dart';
import 'package:repeat_flutter/page/gs_cr_stats_detail/gs_cr_stats_detail_nav.dart';
import 'package:repeat_flutter/page/gs_cr_stats_learn/gs_cr_stats_learn_nav.dart';
import 'package:repeat_flutter/page/gs_cr_stats_review/gs_cr_stats_review_nav.dart';
import 'package:repeat_flutter/page/gs_settings/gs_settings_nav.dart';
import 'package:repeat_flutter/page/gs_settings_data/gs_settings_data_nav.dart';
import 'package:repeat_flutter/page/gs_settings_lang/gs_settings_lang_nav.dart';
import 'package:repeat_flutter/page/gs_settings_theme/gs_settings_theme_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material/sc_cr_material_nav.dart';

enum Nav {
  content("/content"),
  gs("/gs"),
  gsCr("/gs/cr"),
  gsCrContentScan("/gs/cr/content/scan"),
  gsCrContentShare("/gs/cr/content/share"),
  gsCrContentTemplate("/gs/cr/content/template"),
  gsCrRepeat("/gs/cr/repeat"),
  gsCrSettings("/gs/cr/settings"),
  gsCrSettingsEl("/gs/cr/settings/el"),
  gsCrSettingsRel("/gs/cr/settings/rel"),
  gsCrStats("/gs/cr/stats"),
  gsCrStatsDetail("/gs/cr/stats/detail"),
  gsCrStatsLearn("/gs/cr/stats/learn"),
  gsCrStatsReview("/gs/cr/stats/review"),
  gsSettings("/gs/settings"),
  gsSettingsData("/gs/settings/data"),
  gsSettingsLang("/gs/settings/lang"),
  gsSettingsTheme("/gs/settings/theme"),
  scCrMaterial("/sc/cr/material"),
  ;

  final String path;

  const Nav(this.path);

  Future<T?>? push<T>({dynamic arguments}) {
    return Get.toNamed<T>(path, arguments: arguments);
  }

  void until() {
    Get.until((route) => Get.currentRoute == path);
  }

  static back<T>({
    T? result,
    bool closeOverlays = false,
    bool canPop = true,
    int? id,
  }) {
    Get.back(result: result, closeOverlays: closeOverlays, canPop: canPop, id: id);
  }

  static final String initialRoute = gs.path;

  static final List<GetPage> getPages = [
    contentNav(content.path),
    gsNav(gs.path),
    gsCrNav(gsCr.path),
    gsCrContentScanNav(gsCrContentScan.path),
    gsCrContentShareNav(gsCrContentShare.path),
    gsCrContentTemplateNav(gsCrContentTemplate.path),
    gsCrRepeatNav(gsCrRepeat.path),
    gsCrSettingsNav(gsCrSettings.path),
    gsCrSettingsElNav(gsCrSettingsEl.path),
    gsCrSettingsRelNav(gsCrSettingsRel.path),
    gsCrStatsNav(gsCrStats.path),
    gsCrStatsDetailNav(gsCrStatsDetail.path),
    gsCrStatsLearnNav(gsCrStatsLearn.path),
    gsCrStatsReviewNav(gsCrStatsReview.path),
    gsSettingsNav(gsSettings.path),
    gsSettingsDataNav(gsSettingsData.path),
    gsSettingsLangNav(gsSettingsLang.path),
    gsSettingsThemeNav(gsSettingsTheme.path),
    scCrMaterialNav(scCrMaterial.path),
  ];
}
