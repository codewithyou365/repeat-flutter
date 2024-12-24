class StringUtil {
  static List<String> fields(String rawText) {
    return rawText.split(RegExp(r'\s+')).where((element) => element.isNotEmpty).toList();
  }

  static bool compareStringsIgnoringPunctuation(String str1, String str2) {
    String normalize(String input) {
      return input.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '').toLowerCase();
    }

    return normalize(str1) == normalize(str2);
  }
}
