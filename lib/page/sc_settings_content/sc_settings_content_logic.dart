import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/content_web_server.dart';

import 'sc_settings_content_state.dart';

class ScSettingsContentLogic extends GetxController {
  final ScSettingsContentState state = ScSettingsContentState();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    // 默认开：只有显式存了 '0' 才算关。
    state.webNetwork.value = (await Db().db.kvDao.getStr(K.contentWebNetwork)) != '0';
  }

  Future<void> setWebNetwork(bool v) async {
    state.webNetwork.value = v;
    await Db().db.kvDao.insertOrReplace(Kv(K.contentWebNetwork, v ? '1' : '0'));
    // CSP 是发在响应头上的，已经加载过的页面改不了了。把服务停掉，
    // 下次进学习页会重起一遍并按新设置发头，缓存也会跟着作废。
    await ContentWebServer.instance.stop();
  }
}
