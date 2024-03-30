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
    state.indexes.clear();
    state.indexes.addAll(await Db().db.contentIndexDao.findContentIndex());
    update([MainContentLogic.id]);
  }

  delete(String url) async {
    state.indexes.removeWhere((element) => identical(element.url, url));
    update([MainContentLogic.id]);
    await Db().db.contentIndexDao.deleteContentIndex(ContentIndex(url));
  }

  add(String url) async {
    var contentIndex = ContentIndex(url);
    state.indexes.add(contentIndex);
    update([MainContentLogic.id]);
    await Db().db.contentIndexDao.insertContentIndex(contentIndex);
  }

  downloadProgress(int startTime, int count, int total, bool finish) {
    if (finish) {
      state.indexCount.value++;
      state.contentProgress.value = 1;
    } else {
      if (total == -1) {
        int elapse = DateTime.now().millisecondsSinceEpoch - startTime;
        int predict = 5 * 60 * 1000;
        double progress = elapse / predict;
        if (progress > 0.9) {
          state.contentProgress.value = 0.9;
        } else {
          state.contentProgress.value = progress;
        }
      } else {
        state.contentProgress.value = count / total;
      }
    }
  }

  download(String url) async {
    // url = "https://raw.githubusercontent.com/codewithyou365/repeat-flutter/main/README.md";
    var path = await urlToCachePath(CacheFilePrefixPath.content, url);
    await downloadFile(url, path, progressCallback: downloadProgress);
  }
}
