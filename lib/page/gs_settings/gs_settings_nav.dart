import 'package:get/get.dart';
import 'gs_settings_binding.dart';
import 'gs_settings_view.dart';

GetPage gsSettingsNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsSettingsPage(),
    binding: GsSettingsBinding(),
  );
}
