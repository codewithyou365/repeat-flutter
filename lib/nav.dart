import 'package:get/get.dart';
import 'package:repeat_flutter/page/content/content_nav.dart';
import 'package:repeat_flutter/page/editor/editor_nav.dart';
import 'package:repeat_flutter/page/game_list/game_list_nav.dart';
import 'package:repeat_flutter/page/media_list/media_list_nav.dart';
import 'package:repeat_flutter/page/repeat/repeat_nav.dart';
import 'package:repeat_flutter/page/sc/sc_nav.dart';
import 'package:repeat_flutter/page/sc_cr/sc_cr_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material/sc_cr_material_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material_add_chapter/sc_cr_material_add_chapter_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material_edit/sc_cr_material_edit_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material_record/sc_cr_material_record_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material_record_review/sc_cr_material_record_review_nav.dart';
import 'package:repeat_flutter/page/sc_cr_material_search/sc_cr_material_search_nav.dart';
import 'package:repeat_flutter/page/sc_cr_settings_el/sc_cr_settings_el_nav.dart';
import 'package:repeat_flutter/page/sc_cr_settings_rel/sc_cr_settings_rel_nav.dart';
import 'package:repeat_flutter/page/sc_cr_stats/sc_cr_stats_nav.dart';
import 'package:repeat_flutter/page/sc_cr_stats_detail/sc_cr_stats_detail_nav.dart';
import 'package:repeat_flutter/page/sc_cr_stats_review/sc_cr_stats_review_nav.dart';
import 'package:repeat_flutter/page/sc_cr_stats_trend/sc_cr_stats_trend_nav.dart';
import 'package:repeat_flutter/page/sc_settings_ai/sc_settings_ai_nav.dart';
import 'package:repeat_flutter/page/sc_settings_data/sc_settings_data_nav.dart';
import 'package:repeat_flutter/page/sc_settings_lang/sc_settings_lang_nav.dart';
import 'package:repeat_flutter/page/sc_settings_content/sc_settings_content_nav.dart';
import 'package:repeat_flutter/page/sc_settings_theme/sc_settings_theme_nav.dart';
import 'package:repeat_flutter/page/sc_share/sc_share_nav.dart';
import 'package:repeat_flutter/page/scan/scan_nav.dart';
import 'package:repeat_flutter/page/webview/webview_nav.dart';

enum Nav {
  content("/content"),
  editor("/editor"),
  gameList("/game/list"),
  mediaList("/media/list"),
  repeat("/repeat"),
  sc("/sc"),
  scCr("/sc/cr"),
  scCrMaterial("/sc/cr/material"),
  scCrMaterialAddChapter("/sc/cr/material/add/chapter"),
  scCrMaterialEdit("/sc/cr/material/edit"),
  scCrMaterialRecord("/sc/cr/material/record"),
  scCrMaterialRecordReview("/sc/cr/material/record/review"),
  scCrMaterialSearch("/sc/cr/material/search"),
  scCrSettingsEl("/sc/cr/settings/el"),
  scCrSettingsRel("/sc/cr/settings/rel"),
  scCrStats("/sc/cr/stats"),
  scCrStatsDetail("/sc/cr/stats/detail"),
  scCrStatsReview("/sc/cr/stats/review"),
  scCrStatsTrend("/sc/cr/stats/trend"),
  scSettingsAi("/sc/settings/ai"),
  scSettingsData("/sc/settings/data"),
  scSettingsLang("/sc/settings/lang"),
  scSettingsTheme("/sc/settings/theme"),
  scSettingsContent("/sc/settings/content"),
  scShare("/sc/share"),
  scan("/scan"),
  webview("/webview"),
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
    contentNav(content.path),
    editorNav(editor.path),
    gameListNav(gameList.path),
    mediaListNav(mediaList.path),
    repeatNav(repeat.path),
    scNav(sc.path),
    scCrNav(scCr.path),
    scCrMaterialNav(scCrMaterial.path),
    scCrMaterialAddChapterNav(scCrMaterialAddChapter.path),
    scCrMaterialEditNav(scCrMaterialEdit.path),
    scCrMaterialRecordNav(scCrMaterialRecord.path),
    scCrMaterialRecordReviewNav(scCrMaterialRecordReview.path),
    scCrMaterialSearchNav(scCrMaterialSearch.path),
    scCrSettingsElNav(scCrSettingsEl.path),
    scCrSettingsRelNav(scCrSettingsRel.path),
    scCrStatsNav(scCrStats.path),
    scCrStatsDetailNav(scCrStatsDetail.path),
    scCrStatsReviewNav(scCrStatsReview.path),
    scCrStatsTrendNav(scCrStatsTrend.path),
    scSettingsAiNav(scSettingsAi.path),
    scSettingsDataNav(scSettingsData.path),
    scSettingsLangNav(scSettingsLang.path),
    scSettingsThemeNav(scSettingsTheme.path),
    scSettingsContentNav(scSettingsContent.path),
    scShareNav(scShare.path),
    scanNav(scan.path),
    webviewNav(webview.path),
  ];
}
