import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

import 'constant.dart';

class BlankItRightUtils {
  static Future<int> getMaxScore() async {
    var ret = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForMaxScore);
    return ret ?? 10;
  }

  static Future<bool> getIgnorePunctuation() async {
    var ignorePunctuation = false;
    var kip = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForIgnorePunctuation);
    if (kip != null) {
      ignorePunctuation = kip == 1;
    }
    return ignorePunctuation;
  }

  static Future<bool> getIgnoreCase() async {
    var ignoreCase = false;
    var kic = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForIgnoreCase);
    if (kic != null) {
      ignoreCase = kic == 1;
    }
    return ignoreCase;
  }


  static String getBlank(Map<String, dynamic> verseMap, bool ignorePunctuation) {
    if (verseMap[MapKeyEnum.blankItRightList.name] == null) {
      return '';
    }
    final blankItRightList = verseMap[MapKeyEnum.blankItRightList.name] as List<dynamic>;
    var blankItRightUsingIndex = 0;
    if (verseMap[MapKeyEnum.blankItRightUsingIndex.name] != null) {
      blankItRightUsingIndex = verseMap[MapKeyEnum.blankItRightUsingIndex.name] as int;
    }
    final String a = verseMap['a'] ?? '';
    final String b = blankItRightList[blankItRightUsingIndex].toString();
    final buffer = StringBuffer();

    for (int i = 0; i < a.length; i++) {
      final aChar = a[i];
      if (ignorePunctuation && StringUtil.punctuationRegex.hasMatch(aChar)) {
        buffer.write(aChar);
        continue;
      }
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

  static int getScore(String userAnswer, String correctAnswer, String blank, int maxScore, bool ignoreCase) {
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
        if (ignoreCase && userAnswer[i].toLowerCase() == correctAnswer[i].toLowerCase()) {
          rightCount++;
        } else if (userAnswer[i] == correctAnswer[i]) {
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
