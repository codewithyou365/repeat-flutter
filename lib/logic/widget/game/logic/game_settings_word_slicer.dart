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
import 'package:repeat_flutter/logic/game_server/controller/word_slicer/game.dart';
import 'package:repeat_flutter/logic/game_server/controller/word_slicer/utils.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'game_settings.dart';

class GameSettingsWordSlicer extends GameSettings {
  RxBool ignoringPunctuation = RxBool(false);
  RxBool ignoreCase = RxBool(false);
  RxInt maxScoreIndex = RxInt(10);
  RxInt hideContentPercent = RxInt(0);
  late WebServer web;
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
      wordSlicerGame.verseId = verseId ?? 0;
      final text = WordSlicerUtils.getText(wordSlicerGame.verseId);
      if (text != null) {
        wordSlicerGame.setForNewGame(text);
      }
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

    maxScoreIndex.value = await WordSlicerUtils.getMaxScore() - 1;
    hideContentPercent.value = await WordSlicerUtils.getHiddenContentPercent();
  }

  @override
  Future<void> onWebOpen() async {
    wordSlicerGame.clear();
    wordSlicerGame.verseId = await Db().db.kvDao.getInt(K.lastVerseId) ?? 0;
  }

  @override
  Future<void> onWebClose() async {
    wordSlicerGame.clear();
  }

  Future<void> initUsers({bool broadcast = false}) async {
    var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.wordSlicerGameForEditorUserId);
    if (users.isNotEmpty) {
      var index = users.indexWhere((u) => u.id == userId);
      if (index == -1) {
        index = 0;
      }
      await setUser(index);
    }
    await setScore();
  }

  Future<void> setScore() async {
    final userIds = users.map((u) => u.id!).toList();
    var userScores = await Db().db.gameUserScoreDao.list(userIds, GameType.wordSlicer);
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
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.wordSlicerGameForEditorUserId, "${user.id!}"));
    userIndex.value = index;
  }

  void setMaxScore(int index) {
    maxScoreIndex.value = index;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.wordSlicerGameForMaxScore, '${index + 1}'));
  }

  void setHiddenContentPercent(int index) {
    hideContentPercent.value = index;
    Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.wordSlicerGameForHiddenContentPercent, '$index'));
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
          title: I18nKey.editor.tr,
          options: userNames,
          value: userIndex,
          changed: setUser,
          disabled: webOpen,
        );
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
      RowWidget.buildCupertinoPicker(
        title: I18nKey.hiddenContent.tr,
        options: List.generate(11, (i) => '${i * 10}%'),
        value: hideContentPercent,
        changed: setHiddenContentPercent,
        disabled: webOpen,
      ),
    ];
  }
}
