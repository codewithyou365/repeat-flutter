import 'package:get/get.dart';
import 'gs_settings_data_binding.dart';
import 'gs_settings_data_view.dart';

GetPage gsSettingsDataNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsSettingsDataPage(),
    binding: GsSettingsDataBinding(),
  );
}
