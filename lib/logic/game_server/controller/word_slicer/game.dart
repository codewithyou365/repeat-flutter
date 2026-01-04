import 'package:repeat_flutter/common/string_util.dart';

class Word {
  int start;
  int end;
  String word;
  int colorIndex;
  bool right;

  Word({
    required this.start,
    required this.end,
    this.colorIndex = -1,
    this.word = '',
    this.right = false,
  });
}

enum GameStepEnum {
  none,
  selectRule,
  started,
  finished,
}

WordSlicerGame wordSlicerGame = WordSlicerGame();

class Stat {
  int rightCount = 0;
  int errorCount = 0;
  int score = 0;
}

class WordSlicerGame {
  String rawContent = '';
  Map<int, bool> abandonUserIds = {};

  int maxScore = 10;
  int verseId = -1;
  GameStepEnum gameStep = GameStepEnum.selectRule;
  List<List<int>> colorIndexToUserId = [[], [], []];
  List<int> userIds = [];
  Map<String, String> userIdToUserName = {};
  int currUserIndex = -1;
  String content = '';
  String answer = '';
  List<List<int>> colorIndexToSelectedContentIndex = [[], [], []];
  List<Stat> colorIndexToStat = [Stat(), Stat(), Stat()];
  Map<String, int> userIdToScore = {};

  void clear() {
    rawContent = '';
    abandonUserIds = {};

    verseId = -1;
    gameStep = GameStepEnum.selectRule;
    colorIndexToUserId = [[], [], []];
    userIds = [];
    userIdToUserName = {};
    currUserIndex = -1;
    content = '';
    answer = '';
    colorIndexToSelectedContentIndex = [[], [], []];
    colorIndexToStat = [Stat(), Stat(), Stat()];
    userIdToScore = {};
  }

  void setForNewGame(String answer) {
    if (gameStep == GameStepEnum.selectRule) {
      clear();
      return;
    }
    abandonUserIds = {};

    gameStep = GameStepEnum.started;
    content = answer.replaceAll(" ", "").replaceAll(StringUtil.punctuationRegex, "").toLowerCase();
    answer = answer.replaceAll(StringUtil.punctuationRegex, " ");
    while (answer.contains("  ")) {
      answer = answer.replaceAll("  ", " ");
    }
    rawContent = answer.toLowerCase().trim();
    this.answer = '';
    colorIndexToSelectedContentIndex = [[], [], []];
    colorIndexToStat = [Stat(), Stat(), Stat()];
    userIdToScore = {};
  }

  void nextUser() {
    var currUserIndex = wordSlicerGame.currUserIndex;
    wordSlicerGame.currUserIndex = (currUserIndex + 1) % wordSlicerGame.userIds.length;
  }

  bool isSelectedAll() {
    List<int> selectedContentIndex = [];
    for (int i = 0; i < 3; i++) {
      selectedContentIndex.addAll(colorIndexToSelectedContentIndex[i]);
    }
    selectedContentIndex = selectedContentIndex.toSet().toList()..sort();
    if (selectedContentIndex.length != content.length) {
      return false;
    }
    for (int i = 0; i < content.length; i++) {
      if (selectedContentIndex[i] != i) {
        return false;
      }
    }
    return true;
  }

  List<Word> _extractConsecutiveWord(List<int> indexes, int colorIndex) {
    if (indexes.isEmpty) return [];

    indexes.sort();
    List<Word> ranges = [];

    int start = indexes.first;
    int end = start;

    for (int i = 1; i < indexes.length; i++) {
      if (indexes[i] == end + 1) {
        end = indexes[i];
      } else {
        ranges.add(Word(start: start, end: end, colorIndex: colorIndex));
        start = end = indexes[i];
      }
    }

    ranges.add(Word(start: start, end: end, colorIndex: colorIndex));
    return ranges;
  }

  List<Word> _getColorIndexToWords() {
    final List<Word> result = [];

    for (int i = 0; i < 3; i++) {
      final selectedIndexes = colorIndexToSelectedContentIndex[i].toSet().toList();
      result.addAll(_extractConsecutiveWord(selectedIndexes, i));
    }

    result.sort((a, b) => a.start.compareTo(b.start));

    for (final ele in result) {
      final word = content.substring(ele.start, ele.end + 1);
      ele.word = word;
    }

    return result;
  }

  List<Word> _getAnswerWords() {
    final List<Word> result = [];
    if (rawContent.isEmpty || content.isEmpty) return result;
    final words = rawContent.split(' ');
    int cursor = 0;
    for (final w in words) {
      final start = cursor;
      final end = cursor + w.length - 1;
      if (w.isNotEmpty) {
        result.add(
          Word(
            start: start,
            end: end,
            word: w,
          ),
        );

        cursor += w.length;
      }
    }

    return result;
  }

  void setResult() {
    final List<double> temp = [0, 0, 0];
    colorIndexToStat = [Stat(), Stat(), Stat()];

    if (content.isEmpty) return;

    final double scoreEachChar = maxScore / content.length;

    final List<Word> answerWords = _getAnswerWords();
    final List<Word> selectedWords = _getColorIndexToWords();

    for (final selected in selectedWords) {
      final double delta = (selected.word.length * scoreEachChar);
      bool hit = false;
      for (final answer in answerWords) {
        if (answer.start == selected.start) {
          hit = true;
          if (answer.word != selected.word) {
            temp[selected.colorIndex] -= delta;
            colorIndexToStat[selected.colorIndex].errorCount += selected.word.length;
            selected.right = false;
          } else {
            temp[selected.colorIndex] += delta;
            colorIndexToStat[selected.colorIndex].rightCount += selected.word.length;
            selected.right = true;
          }
          break;
        }
      }
      if (!hit) {
        temp[selected.colorIndex] -= delta;
        colorIndexToStat[selected.colorIndex].errorCount += selected.word.length;
        selected.right = false;
      }
    }
    for (final entry in temp.asMap().entries) {
      colorIndexToStat[entry.key].score = entry.value.round();
    }

    for (var userId in userIds) {
      final idx = getColorIndex(userId);
      if (idx == -1) continue;

      final userCount = colorIndexToUserId[idx].length;
      if (userCount == 0) continue;

      userIdToScore[userId.toString()] = (colorIndexToStat[idx].score / userCount).round();
    }
  }

  int differentColorUsers() {
    int count = 0;
    for (int i = 0; i < 3; i++) {
      if (colorIndexToUserId[i].isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  int getColorIndex(int userId) {
    for (int i = 0; i < colorIndexToUserId.length; i++) {
      if (colorIndexToUserId[i].contains(userId)) {
        return i;
      }
    }
    return -1;
  }

  Map<String, dynamic> toJson() {
    return {
      'maxScore': maxScore,
      'verseId': verseId,
      'gameStep': gameStep.name,
      'colorIndexToUserId': colorIndexToUserId,
      'userIds': userIds,
      'userIdToUserName': userIdToUserName,
      'currUserIndex': currUserIndex,
      'content': content,
      'answer': answer,
      'colorIndexToSelectedContentIndex': colorIndexToSelectedContentIndex,
      'colorIndexToStat': colorIndexToStat.map((s) => {'rightCount': s.rightCount, 'errorCount': s.errorCount, 'score': s.score}).toList(),
      'userIdToScore': userIdToScore,
    };
  }
}
