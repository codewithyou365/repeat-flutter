import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/utils.dart';

enum StepEnum {
  none,
  blanking,
  blanked,
  finished,
}

class UserData {
  StepEnum step;
  String submit;
  int score;

  UserData({
    required this.step,
    required this.submit,
    required this.score,
  });
}

final BlankItRightGame blankItRightGame = BlankItRightGame();

class BlankItRightGame {
  bool autoBlank = true;
  int editorUserId = 0;
  int blankContentPercent = 10;
  int maxScore = 10;
  bool ignorePunctuation = true;
  bool ignoreCase = true;

  String? blankContent;
  StepEnum gameStep = StepEnum.blanking;
  Map<int, UserData> userStep = {};

  Future<void> init() async {
    autoBlank = await BlankItRightUtils.getAutoBlank();
    editorUserId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId) ?? 0;
    blankContentPercent = await BlankItRightUtils.getBlankContentPercent();
    maxScore = await BlankItRightUtils.getMaxScore();
    ignorePunctuation = await BlankItRightUtils.getIgnorePunctuation();
    ignoreCase = await BlankItRightUtils.getIgnoreCase();

    clear();
  }

  int? getEditorUserId() {
    return blankItRightGame.autoBlank ? null : blankItRightGame.editorUserId;
  }

  void clear() {
    if (autoBlank) {
      gameStep = StepEnum.blanked;
    } else {
      gameStep = StepEnum.blanking;
    }
    userStep.clear();
    blankContent = null;
  }

  String getBlankContent({
    required Map<String, dynamic> verse,
    required bool focusRefresh,
  }) {
    if (blankContent != null && !focusRefresh) {
      return blankContent!;
    }
    if (autoBlank) {
      final String content = verse['a'] ?? '';
      if (blankContentPercent > 0 && blankContentPercent <= 10 && content.isNotEmpty) {
        final chars = content.split('');

        final List<int> blankableIndexes = [];
        for (int i = 0; i < chars.length; i++) {
          if (chars[i] == ' ') {
            continue;
          }
          if (ignorePunctuation && StringUtil.punctuationRegex.hasMatch(chars[i])) {
            continue;
          }
          blankableIndexes.add(i);
        }
        if (blankableIndexes.isNotEmpty) {
          int hideCount = (blankableIndexes.length * blankContentPercent / 10).round();
          if (hideCount == 0) {
            hideCount = 1;
          }
          blankableIndexes.shuffle();
          for (int i = 0; i < hideCount && i < blankableIndexes.length; i++) {
            chars[blankableIndexes[i]] = '•';
          }
        }
        blankContent = chars.join();
      }
    } else {
      blankContent = BlankItRightUtils.getBlank(verse, ignorePunctuation);
    }
    return blankContent!;
  }

  void join({
    required int userId,
  }) {
    userStep[userId] = UserData(
      step: gameStep,
      submit: '',
      score: 0,
    );
  }

  void blanked() {
    gameStep = StepEnum.blanked;
    for (var userId in userStep.keys) {
      userStep[userId] = UserData(
        step: StepEnum.blanked,
        submit: '',
        score: 0,
      );
    }
  }

  void finished({
    required int userId,
    required String submit,
    required int score,
  }) {
    userStep[userId] = UserData(
      step: StepEnum.finished,
      submit: submit,
      score: score,
    );
  }

  StepEnum getStepEnum({
    required int userId,
  }) {
    var ret = userStep[userId];
    if (ret == null) {
      return gameStep;
    }
    return ret.step;
  }

  String getSubmit({
    required int userId,
  }) {
    var ret = userStep[userId];
    if (ret == null) {
      return '';
    }
    return ret.submit;
  }

  int getScore({
    required int userId,
  }) {
    var ret = userStep[userId];
    if (ret == null) {
      return 0;
    }
    return ret.score;
  }
}
