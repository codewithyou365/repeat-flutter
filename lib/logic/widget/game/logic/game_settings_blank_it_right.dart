import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/game.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/utils.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'game_settings.dart';

class GameSettingsBlankItRight extends GameSettings {
  RxBool ignoringPunctuation = RxBool(false);
  RxBool ignoreCase = RxBool(false);
  RxBool autoBlank = RxBool(false);
  RxInt maxScoreIndex = RxInt(10);
  RxInt blankContentPercent = RxInt(0);
  late WebServer web;
  int verseId = 0;
  RxInt userNumber = RxInt(0);
  RxInt userIndex = RxInt(-1);
  List<GameUser> users = [];
  Map<int, int> userIdToScore = {};
  final SubList<WsEvent> sub = [];
  final SubList<int> subNewGame = [];

  @override
  Future<void> onInit(WebServer web) async {
    this.web = web;
    users = await Db().db.gameUserDao.getAllUser();
    subNewGame.on([EventTopic.newGame], (verseId) async {
      this.verseId = verseId ?? 0;
      blankItRightGame.clear();
    });
    sub.on([EventTopic.wsEvent], (wsEvent) async {
      if (wsEvent == null) {
        return;
      }
      if (wsEvent.wsEventType == WsEventType.add) {
        if (!users.any((user) => user.id == wsEvent.id)) {
          users = await Db().db.gameUserDao.getAllUser();
          await initUsers();
        }
      }
    });

    await initUsers();

    autoBlank.value = await BlankItRightUtils.getAutoBlank();
    maxScoreIndex.value = await BlankItRightUtils.getMaxScore() - 1;
    blankContentPercent.value = await BlankItRightUtils.getBlankContentPercent();
    ignoringPunctuation.value = await BlankItRightUtils.getIgnorePunctuation();
    ignoreCase.value = await BlankItRightUtils.getIgnoreCase();
  }

  @override
  Future<void> onWebOpen() async {
    verseId = await Db().db.kvDao.getInt(K.lastVerseId) ?? 0;
    await blankItRightGame.init();
  }

  @override
  Future<void> onWebClose() async {}

  Future<void> initUsers() async {
    var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
    if (users.isNotEmpty) {
      var index = users.indexWhere((u) => u.id == userId);
      if (index == -1) {
        index = 0;
        await setUser(index);
        blankItRightGame.editorUserId = users[index].id!;
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
    maxScoreIndex.value = index;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForMaxScore, '${index + 1}'));
  }

  void setBlankContentPercent(int index) {
    blankContentPercent.value = index;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForBlankContentPercent, '${index + 1}'));
  }

  void setIgnoringPunctuation(bool ignoringPunctuation) {
    this.ignoringPunctuation.value = ignoringPunctuation;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForIgnorePunctuation, ignoringPunctuation ? '1' : '0'));
  }

  void setIgnoreCase(bool ignoreCase) {
    this.ignoreCase.value = ignoreCase;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForIgnoreCase, ignoreCase ? '1' : '0'));
  }

  void setAutoBlank(bool autoBlank) {
    this.autoBlank.value = autoBlank;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.blockItRightGameForAutoBlank, autoBlank ? '1' : '0'));
  }

  @override
  List<Widget> build() {
    return [
      RowWidget.buildSwitch(
        title: I18nKey.autoBlank.tr,
        value: autoBlank,
        disabled: webOpen,
        set: setAutoBlank,
      ),
      RowWidget.buildDividerWithoutColor(),
      Obx(() {
        List<String> userNames = [];
        for (var i = 0; i < userNumber.value; i++) {
          final user = users[i];
          userNames.add('${user.name}(${userIdToScore[user.id!] ?? 0})');
        }
        if (autoBlank.value) {
          return RowWidget.buildCupertinoPicker(
            title: I18nKey.blankContent.tr,
            options: List.generate(10, (i) => '${i * 10 + 10}%'),
            value: blankContentPercent,
            changed: setBlankContentPercent,
            disabled: webOpen,
          );
        } else {
          return RowWidget.buildCupertinoPicker(
            title: I18nKey.editor.tr,
            options: userNames,
            value: userIndex,
            changed: setUser,
            disabled: webOpen,
          );
        }
      }),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildCupertinoPicker(
        title: I18nKey.maxScore.tr,
        options: List.generate(100, (i) => '${i + 1}'),
        value: maxScoreIndex,
        changed: setMaxScore,
        disabled: webOpen,
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildSwitch(
        title: I18nKey.ignorePunctuation.tr,
        value: ignoringPunctuation,
        disabled: webOpen,
        set: setIgnoringPunctuation,
      ),
      RowWidget.buildDividerWithoutColor(),
      RowWidget.buildSwitch(
        title: I18nKey.ignoreCase.tr,
        value: ignoreCase,
        disabled: webOpen,
        set: setIgnoreCase,
      ),
    ];
  }
}
