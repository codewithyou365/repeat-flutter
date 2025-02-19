import 'package:repeat_flutter/common/string_util.dart';

import 'constant.dart';

class GameLogic {
  static List<String> processWord(String original, String input, List<String> next, List<String> prev, bool matchSingleCharacter, String? skipChar) {
    List<String> originalFields = StringUtil.fields(original);
    List<String> inputFields = StringUtil.fields(input);
    List<String> ret = [];
    if (prev.isEmpty) {
      for (int i = 0; i < originalFields.length; i++) {
        var original = originalFields[i];
        String failed = replaceChar * original.length;
        prev.add(failed);
      }
    }
    for (int i = 0; i < originalFields.length; i++) {
      var original = originalFields[i];
      String prevAnswer = prev[i];
      String failed = replaceChar * original.length;
      if (prevAnswer.replaceAll(replaceChar, '').length != prevAnswer.length && inputFields.isNotEmpty) {
        String answer = processChar(original, inputFields[0], prevAnswer, matchSingleCharacter, skipChar);
        ret.add(answer);

        List<String> nextChars = [];
        for (int j = 0; j < prevAnswer.length; j++) {
          if (prevAnswer[j] != replaceChar) {
            nextChars.add(prevAnswer[j]);
          } else {
            nextChars.add(answer[j]);
          }
        }
        next.add(nextChars.join(''));

        if (answer != failed) {
          inputFields.removeAt(0);
        }
      } else {
        ret.add(failed);
        next.add(prevAnswer);
      }
    }
    ret.addAll(inputFields);
    return ret;
  }

  static String replaceChar = PlaceholderToken.using;

  static String processChar(String original, String input, String preAnswer, bool matchSingleCharacter, String? skipChar) {
    List<String> originalChars = original.split('');
    List<String> inputChars = input.split('');
    List<String> outputChars = (replaceChar * original.length).split('');

    for (int i = 0; i < originalChars.length; i++) {
      var hit = false;
      var needMatched = true;
      if (matchSingleCharacter) {
        needMatched = preAnswer[i] == replaceChar;
      }
      if (needMatched && inputChars.isNotEmpty && originalChars[i].toLowerCase() == inputChars.first.toLowerCase()) {
        hit = true;
      } else if (skipChar != null && needMatched && inputChars.isNotEmpty && inputChars.first == skipChar) {
        hit = true;
      }
      if (hit) {
        outputChars[i] = originalChars[i];
        inputChars.removeAt(0);
      }
    }
    if (inputChars.length < input.length) {
      outputChars.addAll(inputChars);
    }
    return outputChars.join('');
  }
}
