import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:repeat_flutter/logic/download.dart';

import 'main_content_state.dart';

class MainContentLogic extends GetxController {
  static const String id = "MainContentLogicList";
  final MainContentState state = MainContentState();

  init() async {
    state.indexes.addAll(await Db().db.contentIndexDao.findContentIndex());
    update([MainContentLogic.id]);
  }

  delete(BuildContext context) async {
    var url =
        "https://raw.githubusercontent.com/codewithyou365/repeat-flutter/main/README.md";
    var path = await urlToCachePath(CacheFilePrefixPath.content, url);
    await downloadFile(url, path);
  }

  add(String url) async {
    var contentIndex = ContentIndex(url, false);
    state.indexes.add(ContentIndex(url, false));
    update([MainContentLogic.id]);
    Db().db.contentIndexDao.insertContentIndex(contentIndex);
  }

  downloadTest() async {
    var url =
        "https://raw.githubusercontent.com/codewithyou365/repeat-flutter/main/README.md";
    var path = await urlToCachePath(CacheFilePrefixPath.content, url);
    await downloadFile(url, path);
  }
}
