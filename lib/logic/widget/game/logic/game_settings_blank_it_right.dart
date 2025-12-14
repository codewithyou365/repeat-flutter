import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
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
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'game_settings.dart';

class GameSettingsBlankItRight extends GameSettings {
  RxBool ignoringPunctuation = RxBool(false);
  RxInt userNumber = RxInt(0);
  RxInt userIndex = RxInt(-1);
  List<GameUser> users = [];
  Map<int, int> userIdToScore = {};
  final SubList<WsEvent> sub = [];
  final SubList<Game> subNewGame = [];

  @override
  Future<void> onInit() async {
    users = await Db().db.gameUserDao.getAllUser();
    List<int> userIds = users.map((user) => user.getId()).toList();
    Step.blanking(userIds: userIds);
    subNewGame.on([EventTopic.newGame], (game) async {
      Step.blanking(userIds: userIds);
    });
    sub.on([EventTopic.wsEvent], (wsEvent) async {
      if (wsEvent == null) {
        return;
      }
      if (wsEvent.wsEventType == WsEventType.add) {
        if (!users.any((user) => user.id == wsEvent.id)) {
          users = await Db().db.gameUserDao.getAllUser();
        }
      }
      await setScore();
    });

    var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
    if (users.isNotEmpty) {
      var index = users.indexWhere((u) => u.id == userId);
      if (index == -1) {
        index = 0;
      }
      await setUser(index);
    }
    await setScore();

    var ki = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForIgnorePunctuation);
    if (ki != null) {
      ignoringPunctuation.value = ki == 1;
    }
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

  void setIgnoringPunctuation(bool ignoringPunctuation) {
    this.ignoringPunctuation.value = ignoringPunctuation;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForIgnorePunctuation, ignoringPunctuation ? '1' : '0'));
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
      RowWidget.buildSwitch(
        I18nKey.ignorePunctuation.tr,
        ignoringPunctuation,
        setIgnoringPunctuation,
      ),
    ];
  }
}
