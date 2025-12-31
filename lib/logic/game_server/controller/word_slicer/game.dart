import 'dart:async';
import 'dart:ui';

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

class WordSlicerGame {
  Timer? _timer;
  int timerInterval = 10;
  int verseId = -1;
  GameStepEnum gameStep = GameStepEnum.selectRule;
  List<List<int>> colorIndexToUserId = [[], [], []];
  List<int> userIds = [];
  Map<String, String> userIdToUserName = {};
  int currUserIndex = -1;
  String content = '';
  String rawContent = '';
  List<List<int>> colorIndexToSelectedContentIndex = [[], [], []];
  List<int> colorIndexToScore = [0, 0, 0];

  void clear() {
    _timer?.cancel();
    timerInterval = 10;
    verseId = -1;
    gameStep = GameStepEnum.selectRule;
    colorIndexToUserId = [[], [], []];
    userIds = [];
    userIdToUserName = {};
    currUserIndex = -1;
    content = '';
    rawContent = '';
    colorIndexToSelectedContentIndex = [[], [], []];
    colorIndexToScore = [0, 0, 0];
  }

  void start(VoidCallback onTick) {
    _timer?.cancel();
    // _timer = Timer.periodic(Duration(seconds: timerInterval), (t) {
    //   onTick();
    // });
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

  List<Word> extractConsecutiveWord(List<int> indexes, int colorIndex) {
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

  List<Word> getColorIndexToWords() {
    final List<Word> result = [];

    for (int i = 0; i < 3; i++) {
      final selectedIndexes = colorIndexToSelectedContentIndex[i].toSet().toList();
      result.addAll(extractConsecutiveWord(selectedIndexes, i));
    }

    result.sort((a, b) => a.start.compareTo(b.start));

    for (final ele in result) {
      final word = content.substring(ele.start, ele.end + 1);
      ele.word = word;
    }

    return result;
  }

  List<Word> getAnswerWords() {
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

  List<int> getColorIndexToScore() {
    final List<double> temp = [0, 0, 0];
    final List<int> result = [0, 0, 0];
    const int maxScore = 10;

    if (content.isEmpty) return result;

    final double scoreEachChar = maxScore / content.length;

    final List<Word> answerWords = getAnswerWords();
    final List<Word> selectedWords = getColorIndexToWords();

    for (final selected in selectedWords) {
      final double delta = (selected.word.length * scoreEachChar);
      bool hit = false;
      for (final answer in answerWords) {
        if (answer.start == selected.start) {
          hit = true;
          if (answer.word != selected.word) {
            temp[selected.colorIndex] -= delta;
            selected.right = false;
          } else {
            temp[selected.colorIndex] += delta;
            selected.right = true;
          }
          break;
        }
      }
      if (!hit) {
        temp[selected.colorIndex] -= delta;
        selected.right = false;
      }
    }
    for (final entry in temp.asMap().entries) {
      result[entry.key] = entry.value.round();
    }
    return result;
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
      'verseId': verseId,
      'gameStep': gameStep.name,
      'colorIndexToUserId': colorIndexToUserId,
      'userIds': userIds,
      'userIdToUserName': userIdToUserName,
      'currUserIndex': currUserIndex,
      'content': content,
      'colorIndexToSelectedContentIndex': colorIndexToSelectedContentIndex,
      'colorIndexToScore': colorIndexToScore,
    };
  }
}
