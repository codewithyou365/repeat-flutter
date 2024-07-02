import 'package:get/get.dart';
import 'gs_cr_settings_dsc_binding.dart';
import 'gs_cr_settings_dsc_view.dart';

GetPage gsCrSettingsDscNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsCrSettingsDscPage(),
    binding: GsCrSettingsDscBinding(),
  );
}
