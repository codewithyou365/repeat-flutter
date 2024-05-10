import 'package:get/get.dart';

import 'gs_binding.dart';
import 'gs_view.dart';

GetPage gsNav(String path) {
  return GetPage(
    name: path,
    page: () => GsPage(),
    binding: GsBinding(),
  );
}
