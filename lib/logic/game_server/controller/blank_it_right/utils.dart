import 'constant.dart';

class BlankItRightUtils {
  static String getBlank(Map<String, dynamic> verseMap) {
    final blankItRightList = verseMap[MapKeyEnum.blankItRightList.name] as List<dynamic>;
    final blankItRightUsingIndex = verseMap[MapKeyEnum.blankItRightUsingIndex.name] as int;
    final String a = verseMap['a'] ?? '';
    final String b = blankItRightList[blankItRightUsingIndex].toString();
    final buffer = StringBuffer();

    for (int i = 0; i < a.length; i++) {
      final aChar = a[i];
      if (i >= b.length) {
        buffer.write('•');
        continue;
      }
      final bChar = b[i];
      if (aChar == ' ') {
        buffer.write(' ');
      } else if (aChar == bChar) {
        buffer.write(aChar);
      } else {
        buffer.write('•');
      }
    }
    return buffer.toString();
  }

  static int getScore(String userAnswer, String correctAnswer, String blank, int maxScore) {
    int blankCount = 0;
    int rightCount = 0;

    final int len = [
      userAnswer.length,
      correctAnswer.length,
      blank.length,
    ].reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < len; i++) {
      if (blank[i] == '•') {
        blankCount++;
        if (userAnswer[i] == correctAnswer[i]) {
          rightCount++;
        }
      }
    }

    int score = 0;

    if (blankCount > 0) {
      if (rightCount == blankCount) {
        score = maxScore;
      } else {
        score = ((rightCount / blankCount) * maxScore).floor();
      }
    }
    return score;
  }
}
