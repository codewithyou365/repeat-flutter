import 'package:get/get.dart';
import 'gs_cr_content_template_binding.dart';
import 'gs_cr_content_template_view.dart';

GetPage gsCrContentTemplateNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.fadeIn,
    fullscreenDialog: true,
    popGesture: false,
    page: () => GsCrContentTemplatePage(),
    binding: GsCrContentTemplateBinding(),
  );
}
