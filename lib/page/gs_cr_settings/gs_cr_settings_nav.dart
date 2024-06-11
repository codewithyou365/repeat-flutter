import 'package:get/get.dart';
import 'gs_cr_settings_binding.dart';
import 'gs_cr_settings_view.dart';

GetPage gsCrSettingsNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsCrSettingsPage(),
    binding: GsCrSettingsBinding(),
  );
}
