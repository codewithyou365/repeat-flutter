import 'package:get/get.dart';
import 'gs_cr_settings_el_binding.dart';
import 'gs_cr_settings_el_view.dart';

GetPage gsCrSettingsElNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsCrSettingsElPage(),
    binding: GsCrSettingsElBinding(),
  );
}
