import 'package:get/get.dart';
import 'sc_settings_data_binding.dart';
import 'sc_settings_data_page.dart';

GetPage scSettingsDataNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => ScSettingsDataPage(),
    binding: ScSettingsDataBinding(),
  );
}
