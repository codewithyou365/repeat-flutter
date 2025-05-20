import 'dart:convert' as convert;

class ListUtil {
  static List<List<String>> toListList(String? json) {
    try {
      var decodedJson = convert.jsonDecode(json ?? "[]");
      if (decodedJson is List) {
        return decodedJson.map((e) => e is List ? e.map((item) => item.toString()).toList() : []).map((innerList) => innerList.map((item) => item.toString()).toList()).toList();
      }
    } catch (_) {
      print('Failed to decode JSON.');
    }
    return [];
  }

  static List<String> toList(String? json) {
    try {
      var decodedJson = convert.jsonDecode(json ?? "[]");
      if (decodedJson is List) {
        return decodedJson.map((e) => e.toString()).toList();
      }
    } catch (_) {
      print('Failed to decode JSON.');
    }
    return [];
  }
}

extension CaseInsensitiveContains on List<String> {
  bool containsIgnoreCase(String? value) {
    if (value == null) return false;
    return any((element) => element.toLowerCase() == value.toLowerCase());
  }
}