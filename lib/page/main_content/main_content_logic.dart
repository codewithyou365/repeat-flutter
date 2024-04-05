import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/schedule.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/kv.dart';

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

  Future<int> getUnitCount(String url) async {
    var cacheFile = await downloadFilePath(url);
    if (cacheFile == null) {
      return 0;
    }
    var kv = await Kv.fromFile(cacheFile.path, Uri.parse(url));
    var total = 0;
    for (var d in kv.data) {
      total += d.split.length;
    }
    return total;
  }

  Future<int> addToSchedule(String url) async {
    var cacheFile = await downloadFilePath(url);
    if (cacheFile == null) {
      return 0;
    }
    var kv = await Kv.fromFile(cacheFile.path, Uri.parse(url));
    List<Schedule> entities = [];
    for (var d in kv.data) {
      for (var s in d.split) {
        entities.add(Schedule("${kv.rootPath}|${d.index}|${s.index}", 0));
      }
    }
    await Db().db.scheduleDao.insertSchedules(entities);

    var total = 0;
    for (var d in kv.data) {
      total += d.split.length;
    }
    return total;
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
    state.indexCount.value = 0;
    state.indexTotal.value = 1;
    late Kv kv;
    late String rootPath;
    var success = await downloadFile(
      url,
      (fl) async {
        kv = await Kv.fromFile(fl.path, Uri.parse(url));
        rootPath = fl.folderPath.joinPath(kv.rootPath);
        return FileLocation(rootPath, urlToFileName(url));
      },
      progressCallback: downloadProgress,
    );
    if (success) {
      state.indexTotal.value = state.indexTotal.value + kv.data.length;
      for (var v in kv.data) {
        var innerUrl = v.url;
        if (!innerUrl.startsWith("http")) {
          innerUrl = kv.rootUrl.joinPath(v.url);
        }
        await downloadFile(
          innerUrl,
          (fl) async => FileLocation.create(rootPath.joinPath(v.path)),
          progressCallback: downloadProgress,
        );
      }
    }
  }
}
