import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/step.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/utils.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'game_settings.dart';

class GameSettingsBlankItRight extends GameSettings {
  RxBool ignoringPunctuation = RxBool(false);
  RxBool ignoreCase = RxBool(false);
  RxInt maxScoreIndex = RxInt(10);
  late WebServer web;
  int verseId = 0;
  RxInt userNumber = RxInt(0);
  RxInt userIndex = RxInt(-1);
  List<GameUser> users = [];
  Map<int, int> userIdToScore = {};
  final SubList<WsEvent> sub = [];
  final SubList<Game> subNewGame = [];

  @override
  Future<void> onInit(WebServer web) async {
    this.web = web;
    users = await Db().db.gameUserDao.getAllUser();
    Step.blanking(userIds: users.map((user) => user.getId()).toList());
    subNewGame.on([EventTopic.newGame], (game) async {
      verseId = game?.verseId ?? 0;
      Step.blanking(userIds: users.map((user) => user.getId()).toList());
    });
    sub.on([EventTopic.wsEvent], (wsEvent) async {
      if (wsEvent == null) {
        return;
      }
      if (wsEvent.wsEventType == WsEventType.add) {
        if (!users.any((user) => user.id == wsEvent.id)) {
          users = await Db().db.gameUserDao.getAllUser();
          await initUsers(broadcast: true);
        }
      }
    });

    await initUsers();

    maxScoreIndex.value = await BlankItRightUtils.getMaxScore() - 1;
    ignoringPunctuation.value = await BlankItRightUtils.getIgnorePunctuation();
    ignoreCase.value = await BlankItRightUtils.getIgnoreCase();
  }

  @override
  Future<void> onWebOpen() async {}

  Future<void> initUsers({bool broadcast = false}) async {
    var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
    if (users.isNotEmpty) {
      var index = users.indexWhere((u) => u.id == userId);
      if (index == -1) {
        index = 0;
      }
      await setUser(index);
      List<int> userIds = users.map((user) => user.getId()).toList();
      Step.blanking(userIds: userIds);
      if (broadcast) {
        await web.server.broadcast(
          message.Request(
            path: Path.refreshGame,
            data: {
              "verseId": verseId,
            },
          ),
        );
      }
    }
    await setScore();
  }

  Future<void> setScore() async {
    final userIds = users.map((u) => u.id!).toList();
    var userScores = await Db().db.gameUserScoreDao.list(userIds, GameType.blankItRight);
    for (final s in userScores) {
      userIdToScore[s.userId] = s.score;
    }
    // refresh ui.
    userNumber.value = users.length;
  }

  @override
  Future<void> onClose() async {
    sub.off();
  }

  Future<void> setUser(int index) async {
    if (users.isEmpty) {
      return;
    }
    GameUser user = users[index];
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForEditorUserId, "${user.id!}"));
    userIndex.value = index;
  }

  void setMaxScore(int index) {
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForMaxScore, '${index + 1}'));
  }

  void setIgnoringPunctuation(bool ignoringPunctuation) {
    this.ignoringPunctuation.value = ignoringPunctuation;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForIgnorePunctuation, ignoringPunctuation ? '1' : '0'));
  }

  void setIgnoreCase(bool ignoreCase) {
    this.ignoreCase.value = ignoreCase;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForIgnoreCase, ignoreCase ? '1' : '0'));
  }

  @override
  List<Widget> build() {
    return [
      Obx(() {
        List<String> userNames = [];
        for (var i = 0; i < userNumber.value; i++) {
          final user = users[i];
          userNames.add('${user.name}(${userIdToScore[user.id!] ?? 0})');
        }
        return RowWidget.buildCupertinoPicker(
          I18nKey.editor.tr,
          userNames,
          RxInt(userIndex.value),
          changed: setUser,
        );
      }),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildCupertinoPicker(
        I18nKey.maxScore.tr,
        List.generate(100, (i) => '${i + 1}'),
        maxScoreIndex,
        changed: setMaxScore,
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildSwitch(
        I18nKey.ignorePunctuation.tr,
        ignoringPunctuation,
        setIgnoringPunctuation,
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildSwitch(
        I18nKey.ignoreCase.tr,
        ignoreCase,
        setIgnoreCase,
      ),
    ];
  }
}
