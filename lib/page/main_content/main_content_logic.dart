import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:repeat_flutter/logic/download.dart';

import 'main_content_state.dart';

class MainContentLogic extends GetxController {
  final MainContentState state = MainContentState();

  downloadTest(BuildContext context) async {
    var url = "https://raw.githubusercontent.com/codewithyou365/repeat-flutter/main/README.md";
    var path = await urlToCachePath(CacheFilePrefixPath.content, url);
    await downloadFile(url, path);
  }
}
