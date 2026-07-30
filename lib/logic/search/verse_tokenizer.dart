/// 全文检索用的分词器。
///
/// FTS5 自带的 tokenizer 不会切中文，trigram tokenizer 又要求 SQLite 3.34+
/// （安卓要到 14 才稳），所以这里在 Dart 侧先把文本切成空格分隔的 token 串，
/// FTS5 只用最基础的 unicode61。
///
/// 索引和查询必须走同一套切分逻辑，否则搜不到。改动切分规则时，
/// 必须同步把 [VerseTokenizer.schemaVersion] +1，让旧索引失效重建。
class VerseTokenizer {
  static const int schemaVersion = 1;

  /// 中文/日文/韩文：连续段切成相邻两字的 bigram，段长为 1 时取单字。
  static bool _isCjk(int c) {
    return (c >= 0x3400 && c <= 0x4DBF) || // CJK 扩展 A
        (c >= 0x4E00 && c <= 0x9FFF) || // CJK 基本区
        (c >= 0xF900 && c <= 0xFAFF) || // CJK 兼容汉字
        (c >= 0x3040 && c <= 0x30FF) || // 平假名/片假名
        (c >= 0xAC00 && c <= 0xD7AF); // 谚文
  }

  /// 拉丁字母和数字：连续段整体作为一个 token。
  static bool _isWord(int c) {
    return (c >= 0x30 && c <= 0x39) || // 0-9
        (c >= 0x41 && c <= 0x5A) || // A-Z
        (c >= 0x61 && c <= 0x7A); // a-z
  }

  /// 把若干字段切成 token 列表，标点、空白、emoji 都当分隔符丢掉。
  static List<String> tokenize(String text) {
    var result = <String>[];
    var i = 0;
    while (i < text.length) {
      var c = text.codeUnitAt(i);
      if (_isCjk(c)) {
        var start = i;
        while (i < text.length && _isCjk(text.codeUnitAt(i))) {
          i++;
        }
        if (i - start == 1) {
          result.add(text.substring(start, i));
        } else {
          for (var j = start; j < i - 1; j++) {
            result.add(text.substring(j, j + 2));
          }
        }
      } else if (_isWord(c)) {
        var start = i;
        while (i < text.length && _isWord(text.codeUnitAt(i))) {
          i++;
        }
        result.add(text.substring(start, i).toLowerCase());
      } else {
        i++;
      }
    }
    return result;
  }

  /// 写入 FTS5 的正文：多个字段的 token 用空格拼起来。
  static String buildIndexText(Iterable<String?> fields) {
    var result = <String>[];
    for (var field in fields) {
      if (field == null || field.isEmpty) {
        continue;
      }
      result.addAll(tokenize(field));
    }
    return result.join(' ');
  }

  /// 生成 MATCH 表达式，形如 `"世界" AND "界和" AND "hello"`。
  /// 每个 token 用双引号包起来，避免用户输入里的 FTS5 语法字符（* : - ^ 等）被当成语法。
  /// 切不出 token 时返回 null，调用方直接给空结果。
  static String? buildMatchQuery(String input) {
    var tokens = tokenize(input);
    if (tokens.isEmpty) {
      return null;
    }
    return tokens.map((e) => '"${e.replaceAll('"', '""')}"').join(' AND ');
  }
}
