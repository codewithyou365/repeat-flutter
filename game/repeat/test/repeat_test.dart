import 'package:repeat/common/string_util.dart';
import 'package:test/test.dart';
import 'package:collection/equality.dart';

const String replaceChar = "-";

class Match {
  String answer;
  String input;

  Match(this.answer, this.input);

  @override
  bool operator ==(Object other) {
    return other is Match && answer == other.answer && input == other.input;
  }

  @override
  int get hashCode => Object.hash(answer, input);

  @override
  String toString() {
    return '$answer$replaceChar$input';
  }
}

List<List<Match>> generateCombinations(List<String> standardAnswer, List<String> input) {
  final result = <List<Match>>[];
  final reverse = standardAnswer.length < input.length;

  if (reverse) {
    final temp = standardAnswer;
    standardAnswer = input;
    input = temp;
  }

  void combine(List<Match> current, List<String> remaining, int start) {
    if (remaining.isEmpty) {
      result.add(current);
      return;
    }

    for (int i = start; i < standardAnswer.length; i++) {
      final newMatch = List<Match>.from(current);
      newMatch[i] = reverse ? Match(remaining.first, standardAnswer[i]) : Match(standardAnswer[i], remaining.first);
      combine(newMatch, remaining.sublist(1), i + 1);
    }
  }

  final initialMatch = List<Match>.generate(standardAnswer.length, (i) => Match(standardAnswer[i], ""));
  combine(initialMatch, input, 0);

  return result;
}

class WordResult {
  final int score;
  final String answer;
  final String input;

  WordResult(this.score, this.answer, this.input);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WordResult) return false;
    return score == other.score && answer == other.answer && input == other.input;
  }

  @override
  int get hashCode => Object.hash(score, answer, input);

  @override
  String toString() {
    return 'WordResult(score: $score, answer: $answer, input: $input)';
  }
}

WordResult processWord(String answer, String input) {
  final answerChars = answer.padRight(answer.length + input.length, replaceChar).split('');
  final inputChars = input.split('');

  final matches = generateCombinations(answerChars, inputChars);
  int maxScore = 0;
  List<Match> bestMatch = matches[0];

  for (final match in matches) {
    int currentScore = 0;
    int prevOffset = 0;

    for (int i = 0; i < match.length; i++) {
      final v = match[i];
      if (v.answer.toLowerCase() == v.input.toLowerCase()) {
        currentScore += prevOffset == 0 ? 1 : match.length - (i - prevOffset);
        prevOffset = i;
      }
    }

    if (currentScore > maxScore) {
      maxScore = currentScore;
      bestMatch = match;
    }
  }
  //matches.forEach((element) => print(element));
  String outAnswer = '';
  String outInput = '';
  var pruneTailed = false;
  int newScore = 0;
  for (var i = bestMatch.length - 1; i >= 0; i--) {
    final v = bestMatch[i];
    if (!pruneTailed && v.answer == replaceChar && v.input.isEmpty) {
      bestMatch.removeAt(i);
    } else {
      pruneTailed = true;
      if (v.answer == replaceChar) {
        //outAnswer = '$outAnswer';
        outInput = '${v.input}$outInput';
      } else if (v.answer == v.input) {
        outAnswer = '${v.answer}$outAnswer';
        outInput = '${v.answer}$outInput';
        newScore++;
      } else if (v.input.isEmpty) {
        outAnswer = '$replaceChar$outAnswer';
        outInput = '$replaceChar$outInput';
      } else {
        outAnswer = '$replaceChar$outAnswer';
        outInput = '${v.input}$outInput';
      }
    }
  }
  if (outInput.isNotEmpty && outAnswer.isNotEmpty && outInput == outAnswer && !outAnswer.contains(replaceChar) && !outInput.contains(replaceChar)) {
    newScore++;
  }
  return WordResult(newScore, outAnswer, outInput);
}

class SentenceResult {
  List<String> answer = [];
  List<String> input = [];

  SentenceResult(this.answer, this.input);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SentenceResult) return false;
    var listEquality = ListEquality();
    return listEquality.equals(answer, other.answer) && listEquality.equals(input, other.input);
  }

  @override
  int get hashCode => Object.hash(answer, input);

  @override
  String toString() {
    return 'SentenceResult(answer: $answer, input: $input)';
  }
}

SentenceResult processSentence(String standardAnswer, String input, List<String> showAnswerWords) {
  List<String> inputWords = StringUtil.fields(input);
  List<String> standardAnswerWords = StringUtil.fields(standardAnswer);
  if (showAnswerWords.isEmpty) {
    for (int i = 0; i < standardAnswerWords.length; i++) {
      var original = standardAnswerWords[i];
      String failed = replaceChar * original.length;
      showAnswerWords.add(failed);
    }
  }
  Converter converter = toConverter(standardAnswerWords, showAnswerWords);
  standardAnswerWords = converter.unfinishedWords;
  standardAnswerWords.addAll(List.filled(inputWords.length, ''));
  List<List<Match>> matches = generateCombinations(standardAnswerWords, inputWords);
  int maxScore = -1;
  List<Match> bestMatch = [];
  List<WordResult> bestResult = [];
  Map<String, WordResult> cache = {};
  for (final match in matches) {
    int currentScore = 0;
    List<WordResult> result = [];
    for (int i = 0; i < match.length; i++) {
      final v = match[i];
      var key = "${v.answer},${v.input}";
      WordResult? wordResult = cache[key];
      if (wordResult == null) {
        wordResult = processWord(v.answer, v.input);
        cache[key] = wordResult;
      }
      result.add(wordResult);
      currentScore += wordResult.score;
    }

    if (currentScore > maxScore) {
      maxScore = currentScore;
      bestMatch = match;
      bestResult = result;
    }
  }

  List<String> outAnswer = [];
  List<String> outInput = [];
  var pruneTailed = false;

  for (var i = bestMatch.length - 1; i >= 0; i--) {
    final v = bestMatch[i];

    if (!pruneTailed && v.answer.isEmpty && v.input.isEmpty) {
      bestMatch.removeAt(i);
      continue;
    }
    final vr = bestResult[i];
    pruneTailed = true;

    outAnswer.insert(0, vr.answer);
    outInput.insert(0, vr.input);
  }
  // cache.forEach((key, value) => print("$key: $value"));
  // matches.forEach((element) => print(element));
  return SentenceResult(converter.toShowAnswer(outAnswer), converter.toShowInput(outInput));
}

class Converter {
  List<String> finishedWords = [];
  List<String> unfinishedWords = [];
  List<String> showAnswerWords = [];
  List<bool> index = [];

  Converter(this.finishedWords, this.unfinishedWords, this.showAnswerWords, this.index);

  List<String> toShowAnswer(List<String> outAnswer) {
    List<String> ret = [];
    int finishedOffset = 0;
    int unfinishedOffset = 0;
    for (int i = 0; i < index.length; i++) {
      if (index[i]) {
        ret.add(finishedWords[finishedOffset++]);
      } else {
        var a = showAnswerWords[i];
        var b = outAnswer[unfinishedOffset++];
        var result = '';
        for (int j = 0; j < a.length; j++) {
          String charA = a[j];
          String charB = b[j];
          if (charA != replaceChar) {
            result += charA;
          } else if (charB != replaceChar) {
            result += charB;
          } else {
            result += replaceChar;
          }
        }
        ret.add(result);
      }
    }

    return ret;
  }

  List<String> toShowInput(List<String> outInput) {
    List<String> ret = [];
    int finishedOffset = 0;
    int unfinishedOffset = 0;
    for (int i = 0; i < index.length; i++) {
      if (index[i]) {
        ret.add(replaceChar * finishedWords[finishedOffset++].length);
      } else {
        ret.add(outInput[unfinishedOffset++]);
      }
    }
    var remain = outInput.sublist(unfinishedOffset);
    if (remain.isNotEmpty) {
      ret.addAll(remain);
    }
    return ret;
  }
}

Converter toConverter(List<String> standardAnswerWords, List<String> showAnswerWords) {
  Map<int, String> finish = {};
  for (int i = 0; i < showAnswerWords.length; i++) {
    String word = showAnswerWords[i];
    if (!word.contains(replaceChar)) {
      finish[i] = word;
    }
  }
  List<bool> index = [];
  List<String> unfinishedWords = [];
  List<String> finishedWords = [];
  for (int i = 0; i < standardAnswerWords.length; i++) {
    bool finished = finish[i] != null;
    if (finished) {
      index.add(true);
      finishedWords.add(standardAnswerWords[i]);
    } else {
      index.add(false);
      unfinishedWords.add(standardAnswerWords[i]);
    }
  }

  return Converter(finishedWords, unfinishedWords, showAnswerWords, index);
}

void main() {
  test('Word Processing Tests', () {
    const answer = "analysis";
    expect(
      processWord("is", "al"),
      WordResult(
        0,
        "--",
        "al",
      ),
    );
    expect(
      processWord(answer, "i"),
      WordResult(
        1,
        "------i-",
        "------i-",
      ),
    );
    expect(
      processWord("analssss", "ss"),
      WordResult(
        2,
        "----ss--",
        "----ss--",
      ),
    );
    expect(
      processWord(answer, "al"),
      WordResult(
        2,
        "--al----",
        "--al----",
      ),
    );

    expect(
      processWord(answer, "ss"),
      WordResult(
        2,
        "-----s-s",
        "-----s-s",
      ),
    );

    expect(
      processWord(answer, "thisa"),
      WordResult(
        2,
        "------is",
        "th----isa",
      ),
    );

    expect(
      processWord(answer, "analysis"),
      WordResult(
        9,
        "analysis",
        "analysis",
      ),
    );

    expect(
      processWord(answer, "anasixs"),
      WordResult(
        5,
        "ana--si-",
        "ana--sixs",
      ),
    );
  });

  test('Sentence Processing Tests', () {
    const answer = "this is an apple";
    SentenceResult sr = processSentence(answer, "is al x y z", []);
    expect(
      sr,
      SentenceResult(["----", "is", "--", "a--l-"], ["----", "is", "--", "a--l-", "x", "y", "z"]),
    );

    sr = processSentence(answer, "this als an", sr.answer);
    expect(
      sr,
      SentenceResult(["this", "is", "a-", "a--l-"], ["this", "--", "als", "an---"]),
    );

    sr = processSentence(answer, "an apple", sr.answer);
    expect(
      sr,
      SentenceResult(["this", "is", "an", "apple"], ["----", "--", "an", "apple"]),
    );
  });

  test('Sentence Processing Tests1', () {
    const answer = "this is an apple";
    SentenceResult sr = processSentence(answer, "z", []);
    expect(
      sr,
      SentenceResult(["----", "--", "--", "-----"], ["----", "--", "--", "-----"]),
    );
  });
}
