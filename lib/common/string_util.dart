import 'dart:math';

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

  static String limit(String str, int limit) {
    if (str.length > limit) {
      return "${str.substring(0, limit)}...";
    }
    return str;
  }

  static List<String> splitN(String str, String delimiter, int limit) {
    if (limit <= 0) return [];

    List<String> parts = str.split(delimiter);
    if (parts.length <= limit) return parts;

    List<String> result = parts.sublist(0, limit - 1);
    result.add(parts.sublist(limit - 1).join(delimiter));
    return result;
  }

  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static const _char09 = '0123456789';
  static final Random _rnd = Random();

  static String generateRandomString(int length) => String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  static String generateRandom09(int length) => String.fromCharCodes(Iterable.generate(length, (_) => _char09.codeUnitAt(_rnd.nextInt(_char09.length))));
}
