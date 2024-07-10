import 'package:get/get.dart';
import 'gs_cr_settings_rel_binding.dart';
import 'gs_cr_settings_rel_view.dart';

GetPage gsCrSettingsRelNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsCrSettingsRelPage(),
    binding: GsCrSettingsRelBinding(),
  );
}
