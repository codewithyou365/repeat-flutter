import 'package:get/get.dart';
import 'package:repeat_flutter/page/book_editor/book_editor_nav.dart';
import 'package:repeat_flutter/page/content/content_nav.dart';
import 'package:repeat_flutter/page/editor/editor_nav.dart';
import 'package:repeat_flutter/page/repeat/repeat_nav.dart';
import 'package:repeat_flutter/page/sc/sc_nav.dart';
import 'package:repeat_flutter/page/sc_cr/sc_cr_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material/sc_cr_material_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material_share/sc_cr_material_share_nav.dart';
import 'package:repeat_flutter/page/sc_cr_settings/sc_cr_settings_nav.dart';
import 'package:repeat_flutter/page/sc_cr_settings_el/sc_cr_settings_el_nav.dart';
import 'package:repeat_flutter/page/sc_cr_settings_rel/sc_cr_settings_rel_nav.dart';
import 'package:repeat_flutter/page/sc_cr_stats/sc_cr_stats_nav.dart';
import 'package:repeat_flutter/page/sc_cr_stats_detail/sc_cr_stats_detail_nav.dart';
import 'package:repeat_flutter/page/sc_cr_stats_review/sc_cr_stats_review_nav.dart';
import 'package:repeat_flutter/page/sc_settings/sc_settings_nav.dart';
import 'package:repeat_flutter/page/sc_settings_data/sc_settings_data_nav.dart';
import 'package:repeat_flutter/page/sc_settings_lang/sc_settings_lang_nav.dart';
import 'package:repeat_flutter/page/sc_settings_theme/sc_settings_theme_nav.dart';
import 'package:repeat_flutter/page/scan/scan_nav.dart';

enum Nav {
  bookEditor("/book/editor"),
  content("/content"),
  editor("/editor"),
  repeat("/repeat"),
  sc("/sc"),
  scCr("/sc/cr"),
  scCrMaterial("/sc/cr/material"),
  scCrMaterialShare("/sc/cr/material/share"),
  scCrSettings("/sc/cr/settings"),
  scCrSettingsEl("/sc/cr/settings/el"),
  scCrSettingsRel("/sc/cr/settings/rel"),
  scCrStats("/sc/cr/stats"),
  scCrStatsDetail("/sc/cr/stats/detail"),
  scCrStatsReview("/sc/cr/stats/review"),
  scSettings("/sc/settings"),
  scSettingsData("/sc/settings/data"),
  scSettingsLang("/sc/settings/lang"),
  scSettingsTheme("/sc/settings/theme"),
  scan("/scan"),
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

  static final String initialRoute = sc.path;

  static final List<GetPage> getPages = [
    bookEditorNav(bookEditor.path),
    contentNav(content.path),
    editorNav(editor.path),
    repeatNav(repeat.path),
    scNav(sc.path),
    scCrNav(scCr.path),
    scCrMaterialNav(scCrMaterial.path),
    scCrMaterialShareNav(scCrMaterialShare.path),
    scCrSettingsNav(scCrSettings.path),
    scCrSettingsElNav(scCrSettingsEl.path),
    scCrSettingsRelNav(scCrSettingsRel.path),
    scCrStatsNav(scCrStats.path),
    scCrStatsDetailNav(scCrStatsDetail.path),
    scCrStatsReviewNav(scCrStatsReview.path),
    scSettingsNav(scSettings.path),
    scSettingsDataNav(scSettingsData.path),
    scSettingsLangNav(scSettingsLang.path),
    scSettingsThemeNav(scSettingsTheme.path),
    scanNav(scan.path),
  ];
}
