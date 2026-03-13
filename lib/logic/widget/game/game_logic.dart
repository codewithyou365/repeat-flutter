import 'dart:ui';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/widget/user_manager.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/webview/webview_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'game_page.dart';
import 'game_state.dart';

class GameLogic<T extends GetxController> {
  static const int defaultPort = 4321;
  RxInt port = defaultPort.obs;
  static const String bodyId = "GameLogic.bodyId";
  final T parentLogic;
  late UserManager userManager = UserManager<T>(parentLogic);
  late WebServer web;

  final GameState state = GameState();
  final SubList<WsEvent> sub = [];
  final SubList<int> subAllowRegisterNumber = [];

  final GamePage page = GamePage<T>();

  late VoidCallback onOpenWeb;

  GameLogic({
    required this.parentLogic,
    required VoidCallback tapLeft,
    required VoidCallback tapRight,
    required VoidCallback tapMiddle,
    required VoidCallback longTapMiddle,
  }) {
    web = WebServer(
      tapLeft: tapLeft,
      tapRight: tapRight,
      tapMiddle: tapMiddle,
      longTapMiddle: longTapMiddle,
    );
  }

  Future<bool> init(VoidCallback onOpenWeb) async {
    this.onOpenWeb = onOpenWeb;
    state.games = await Db().db.gameDao.getByClassroomId(Classroom.curr);
    if (state.games.isEmpty) {
      return false;
    }
    var lastGameIndex = await Db().db.crKvDao.getInt(Classroom.curr, CrK.lastGameIndex) ?? 0;
    if (lastGameIndex >= state.games.length) {
      lastGameIndex = 0;
      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.lastGameIndex, '0'));
    }
    state.lastGameIndex = lastGameIndex;
    port.value = await Db().db.kvDao.getIntWithDefault(K.gameServerPort, port.value);
    if (port.value > 50000) {
      port.value = defaultPort;
    }
    final adminEnable = await Db().db.kvDao.getInt(K.adminEnable) ?? 0;
    state.adminEnableRx.value = adminEnable != 0;
    await userManager.init(web);
    return true;
  }

  Future<void> open() async {
    sub.off();
    subAllowRegisterNumber.off();
    state.online.value = getOnline();
    state.users = await Db().db.gameUserDao.getAllUser();
    sub.on([EventTopic.wsEvent], (wsEvent) async {
      state.online.value = getOnline();
      if (wsEvent == null) {
        return;
      }
      if (wsEvent.wsEventType == WsEventType.add) {
        if (!state.users.any((user) => user.id == wsEvent.id)) {
          state.users = await Db().db.gameUserDao.getAllUser();
          await refreshUsers();
        }
      }
    });
    subAllowRegisterNumber.on([EventTopic.allowRegisterNumber], (v) {
      if (v != null) {
        userManager.allowRegisterNumber = v;
        state.online.value = getOnline();
      }
    });
    await refreshUsers();
    return page.open(this).then((_) {
      sub.off();
      subAllowRegisterNumber.off();
    });
  }

  Future<Game?> getGame() async {
    if (state.games.isEmpty) {
      return null;
    }
    if (state.lastGameIndex >= state.games.length) {
      state.lastGameIndex = 0;
      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.lastGameIndex, '0'));
    }
    return state.games[state.lastGameIndex];
  }

  Future<void> refreshUsers() async {
    var userId = await Db().db.kvDao.getInt(K.adminId);
    if (state.users.isNotEmpty) {
      var index = state.users.indexWhere((u) => u.id == userId);
      if (index == -1) {
        index = 0;
      }
      await setUser(index);
    }
    await setScore();
  }

  void changeGame(int index) async {
    state.lastGameIndex = index;
    parentLogic.update([bodyId]);
    await Db().db.kvDao.insertOrReplace(Kv(K.lastGameIndex, "${state.lastGameIndex}"));
    await setScore();
  }

  String getOnline() {
    return "${web.server.nodes.userId2Node.length} / ${userManager.allowRegisterNumber}";
  }

  void switchWebForBtn(bool value) async {
    AwaitUtil.tryDo(() async {
      await switchWeb(value);
    });
  }

  Future<void> switchWeb(bool value) async {
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
          final game = await getGame();
          if (game == null) {
            return;
          }
          GameState.game = game;
          final enable = await Db().db.kvDao.getInt(K.adminEnable) ?? 0;
          GameState.adminEnable = enable != 0;
          GameState.adminId = await Db().db.kvDao.getInt(K.adminId) ?? 0;
          await web.start(game.bookId, game.hash, game.service, port.value);
          state.urls = [];
          var ips = await Ip.getLanIps();
          for (var i = 0; i < ips.length; i++) {
            String url = ips[i];
            state.urls.add('https://$url:${port.value}');
          }
          onOpenWeb();
          Snackbar.show('game service started');
        } catch (e) {
          await Db().db.kvDao.insertOrReplace(Kv(K.gameServerPort, '${port.value + 10}'));
          await closeWeb();
          Snackbar.show('Error starting game server: $e \n System has changed the port, please try again');
          Get.back();
          return;
        }
      } else {
        await closeWeb();
        GameState.game = null;
        GameState.adminEnable = false;
        GameState.adminId = 0;
      }
    } finally {
      state.openPending = false;
      state.open.value = value;
    }
  }

  Future<void> closeWeb() async {
    try {
      await web.stop();
      state.urls = [];
      Snackbar.show('game service stopped');
    } catch (e) {
      Snackbar.show('Error Stop Web: $e');
      return;
    }
  }

  Future<void> openWebview() async {
    Nav.webview.push(
      arguments: WebviewArgs(
        initialUrl: "https://127.0.0.1:${port.value}",
        pageTitle: GameState.game?.name ?? '',
      ),
    );
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

  Future<void> setAdminEnable(bool v) async {
    final i = v == true ? 1 : 0;
    state.adminEnableRx.value = v;
    await Db().db.kvDao.insertOrReplace(Kv(K.adminEnable, "$i"));
  }

  Future<void> setUser(int index) async {
    if (state.users.isEmpty) {
      return;
    }
    GameUser user = state.users[index];
    await Db().db.kvDao.insertOrReplace(Kv(K.adminId, "${user.id!}"));
    state.userIndex.value = index;
  }

  List<String> listGameNames() {
    return state.games.map((game) => game.name).toList();
  }

  Future<void> setScore() async {
    var game = await getGame();
    if (game == null) {
      return;
    }
    final userIds = state.users.map((u) => u.id!).toList();
    var userScores = await Db().db.gameUserScoreDao.list(userIds, game.id ?? 0);
    for (final s in userScores) {
      state.userIdToScore[s.userId] = s.score;
    }
    // refresh ui.
    state.userNumber.value = state.users.length;
  }
}
