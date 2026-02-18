import 'dart:ui';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/widget/game/logic/game_settings.dart';
import 'package:repeat_flutter/logic/widget/game/logic/game_settings_type.dart';
import 'package:repeat_flutter/logic/widget/game/logic/game_settings_word_slicer.dart';
import 'package:repeat_flutter/logic/widget/user_manager.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'game_page.dart';
import 'game_state.dart';
import 'logic/game_settings_blank_it_right.dart';

class GameLogic<T extends GetxController> {
  static const int defaultPort = 4321;
  RxInt port = defaultPort.obs;
  static const String bodyId = "GameLogic.bodyId";
  final T parentLogic;
  late UserManager userManager = UserManager<T>(parentLogic);
  WebServer web = WebServer();
  final GameState state = GameState();
  final SubList<WsEvent> sub = [];
  final SubList<int> subAllowRegisterNumber = [];

  final GamePage page = GamePage<T>();

  late VoidCallback onOpenWeb;
  final Map<GameType, GameSettings> gameTypeToGameSettings = {};

  GameLogic(this.parentLogic) {
    gameTypeToGameSettings[GameType.type] = GameSettingsType();
    gameTypeToGameSettings[GameType.blankItRight] = GameSettingsBlankItRight();
    gameTypeToGameSettings[GameType.wordSlicer] = GameSettingsWordSlicer();
  }

  Future<void> init(VoidCallback onOpenWeb) async {
    this.onOpenWeb = onOpenWeb;
    var lastGameIndex = await Db().db.kvDao.getInt(K.lastGameIndex) ?? 1;
    state.game = lastGameIndex - 1;
    GameState.lastGameIndex = lastGameIndex;
    port.value = await Db().db.kvDao.getIntWithDefault(K.gameServerPort, port.value);
    if (port.value > 50000) {
      port.value = defaultPort;
    }
    await userManager.init(web);
  }

  Future<void> open() async {
    for (var v in gameTypeToGameSettings.values) {
      await v.onInit(web);
    }
    state.game = GameState.lastGameIndex - 1;
    sub.off();
    subAllowRegisterNumber.off();
    state.online.value = getOnline();
    sub.on([EventTopic.wsEvent], (_) {
      state.online.value = getOnline();
    });
    subAllowRegisterNumber.on([EventTopic.allowRegisterNumber], (v) {
      if (v != null) {
        userManager.allowRegisterNumber = v;
        state.online.value = getOnline();
      }
    });

    return page.open(this).then((_) {
      sub.off();
      subAllowRegisterNumber.off();
      for (var v in gameTypeToGameSettings.values) {
        v.onClose();
      }
    });
  }

  void changeGame(int index) {
    GameState.lastGameIndex = index + 1;
    parentLogic.update([bodyId]);
    Db().db.kvDao.insertOrReplace(Kv(K.lastGameIndex, "${GameState.lastGameIndex}"));
  }

  String get title {
    return "${I18nKey.game.tr}(${state.open.value})";
  }

  String getOnline() {
    return "${web.server.nodes.userId2Node.length} / ${userManager.allowRegisterNumber}";
  }

  void switchWeb(bool value) async {
    if (state.openPending) {
      return;
    }
    state.openPending = true;
    try {
      if (state.open.value == value) {
        return;
      }
      if (value) {
        try {
          int gamePort = await web.start(port.value);
          state.urls = [];
          var ips = await Ip.getLanIps();
          for (var i = 0; i < ips.length; i++) {
            String url = ips[i];
            state.urls.add('https://$url:$gamePort');
          }
          onOpenWeb();
          for (var v in gameTypeToGameSettings.values) {
            v.setWebOpen(true);
            await v.onWebOpen();
          }
        } catch (e) {
          await Db().db.kvDao.insertOrReplace(Kv(K.gameServerPort, '${port.value + 10}'));
          Snackbar.show('Error starting game server: $e \n System has changed the port, please try again');
          closeWeb(tip: false);
          Get.back();
          return;
        }
      } else {
        closeWeb();
      }
    } finally {
      state.openPending = false;
      state.open.value = value;
    }
  }

  Future<void> closeWeb({tip = true}) async {
    try {
      for (var v in gameTypeToGameSettings.values) {
        await v.onWebClose();
        v.setWebOpen(false);
      }
      await web.stop();
      state.urls = [];
    } catch (e) {
      if (tip) {
        Snackbar.show('Error Stop Web: $e');
      }
      return;
    }
  }

  Future<void> openCredentialDialog() async {
    RxString credential = RxString(await getGamePassword());
    MsgBox.myDialog(
      title: I18nKey.keyTitle.tr,
      content: Obx(() {
        if (credential.value.isEmpty) {
          credential.value = I18nKey.noPassword.tr;
        }
        return MsgBox.content(credential.value);
      }),
      action: MsgBox.buttonsWithDivider(
        buttons: [
          MsgBox.button(
            text: I18nKey.close.tr,
            onPressed: () {
              Get.back();
            },
          ),
          MsgBox.button(
            text: I18nKey.clear.tr,
            onPressed: () async {
              await clearGamePassword();
              credential.value = I18nKey.noPassword.tr;
            },
          ),
          MsgBox.button(
            text: I18nKey.refresh.tr,
            onPressed: () async {
              credential.value = await refreshGamePassword();
            },
          ),
        ],
      ),
    );
  }

  Future<String> getGamePassword() async {
    return await Db().db.kvDao.getStr(K.gamePassword) ?? '';
  }

  Future<String> refreshGamePassword() async {
    var password = StringUtil.generateRandom09(6);
    final now = DateTime.now().millisecondsSinceEpoch;
    await Db().db.kvDao.insertOrReplace(Kv(K.gamePassword, password));
    await Db().db.kvDao.insertOrReplace(Kv(K.gamePasswordCreateTime, now.toString()));
    web.server.broadcast(message.Request(path: Path.kick));
    return password;
  }

  Future<void> clearGamePassword() async {
    await Db().db.kvDao.insertOrReplace(Kv(K.gamePassword, ''));
    await Db().db.kvDao.insertOrReplace(Kv(K.gamePasswordCreateTime, '0'));
  }
}
