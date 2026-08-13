import 'package:repeat_flutter/common/string_util.dart';

/// 对比时哪些字符不参与判定。被忽略的字符照常显示，只是不算差异。
class TextDiffOptions {
  final bool ignoreSpace;
  final bool ignorePunctuation;
  final bool ignoreCase;
  final bool ignoreNumber;

  const TextDiffOptions({
    this.ignoreSpace = true,
    this.ignorePunctuation = true,
    this.ignoreCase = true,
    this.ignoreNumber = false,
  });
}

enum DiffMark {
  /// 两边对上了，或者按配置被忽略——两种都不标色
  same,

  /// 对不上：在答案里是漏的，在输入里是错的/多的
  diff,
}

class DiffSpan {
  final String text;
  final DiffMark mark;

  const DiffSpan(this.text, this.mark);
}

class TextDiffResult {
  /// 正确答案的分段
  final List<DiffSpan> expected;

  /// 用户输入的分段
  final List<DiffSpan> actual;

  /// 差异处数：对齐后连续的一段删除/插入算一处
  final int diffCount;

  const TextDiffResult(this.expected, this.actual, this.diffCount);

  bool get same => diffCount == 0;
}

class TextDiff {
  static final _spaceRegex = RegExp(r'\s');
  static final _numberRegex = RegExp(r'\p{N}', unicode: true);

  /// 超过这个长度就不做 LCS 了，O(n*m) 会卡住 UI。正文一般几十到几百字符。
  static const int maxLenForLcs = 1500;

  static TextDiffResult compare(String expected, String actual, TextDiffOptions o) {
    final e = _Seq(expected, o);
    final a = _Seq(actual, o);

    if (e.keys.length > maxLenForLcs || a.keys.length > maxLenForLcs) {
      // 退化处理：整体一样就全标 same，不一样就把参与判定的字符全标 diff。
      final equal = e.keys.join() == a.keys.join();
      return TextDiffResult(
        e.spansAll(equal ? DiffMark.same : DiffMark.diff),
        a.spansAll(equal ? DiffMark.same : DiffMark.diff),
        equal ? 0 : 1,
      );
    }

    final matchedE = List<bool>.filled(e.keys.length, false);
    final matchedA = List<bool>.filled(a.keys.length, false);
    final diffCount = _lcs(e.keys, a.keys, matchedE, matchedA);

    return TextDiffResult(e.spans(matchedE), a.spans(matchedA), diffCount);
  }

  /// 标准 LCS DP + 回溯。回溯时给两边打上"匹配到了"的标记，
  /// 顺便把连着的删除/插入并成一处差异。
  static int _lcs(List<String> x, List<String> y, List<bool> matchedX, List<bool> matchedY) {
    final n = x.length;
    final m = y.length;
    // dp[i][j]：x[i..] 和 y[j..] 的最长公共子序列长度
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        if (x[i] == y[j]) {
          dp[i][j] = dp[i + 1][j + 1] + 1;
        } else {
          dp[i][j] = dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
        }
      }
    }

    var diffCount = 0;
    var inDiff = false;
    var i = 0;
    var j = 0;
    while (i < n && j < m) {
      if (x[i] == y[j]) {
        matchedX[i] = true;
        matchedY[j] = true;
        i++;
        j++;
        inDiff = false;
      } else {
        if (!inDiff) {
          diffCount++;
          inDiff = true;
        }
        if (dp[i + 1][j] >= dp[i][j + 1]) {
          i++;
        } else {
          j++;
        }
      }
    }
    if (i < n || j < m) {
      // 尾巴上还剩东西，整体算一处（紧接着上一处差异的话就并进去）
      if (!inDiff) {
        diffCount++;
      }
    }
    return diffCount;
  }
}

/// 原文的两份视图：显示用的字符列表，和参与判定的字符（[keys]）及其在原文里的下标。
class _Seq {
  final List<String> chars = [];

  /// 参与判定的字符（已按 ignoreCase 归一）
  final List<String> keys = [];

  /// keys[i] 对应 chars 里的下标
  final List<int> keyToChar = [];

  _Seq(String raw, TextDiffOptions o) {
    for (final ch in raw.characters) {
      final index = chars.length;
      chars.add(ch);
      if (_ignored(ch, o)) {
        continue;
      }
      keys.add(o.ignoreCase ? ch.toLowerCase() : ch);
      keyToChar.add(index);
    }
  }

  static bool _ignored(String ch, TextDiffOptions o) {
    if (o.ignoreSpace && TextDiff._spaceRegex.hasMatch(ch)) {
      return true;
    }
    if (o.ignorePunctuation && StringUtil.punctuationRegex.hasMatch(ch)) {
      return true;
    }
    if (o.ignoreNumber && TextDiff._numberRegex.hasMatch(ch)) {
      return true;
    }
    return false;
  }

  List<DiffSpan> spans(List<bool> matched) {
    // 被忽略的字符不参与判定，显示上跟"对上了"一样不标色。
    final marks = List<DiffMark>.filled(chars.length, DiffMark.same);
    for (var i = 0; i < keyToChar.length; i++) {
      marks[keyToChar[i]] = matched[i] ? DiffMark.same : DiffMark.diff;
    }
    return _merge(marks);
  }

  List<DiffSpan> spansAll(DiffMark mark) {
    final marks = List<DiffMark>.filled(chars.length, DiffMark.same);
    for (final index in keyToChar) {
      marks[index] = mark;
    }
    return _merge(marks);
  }

  List<DiffSpan> _merge(List<DiffMark> marks) {
    final result = <DiffSpan>[];
    final buf = StringBuffer();
    DiffMark? curr;
    for (var i = 0; i < chars.length; i++) {
      if (curr != null && marks[i] != curr) {
        result.add(DiffSpan(buf.toString(), curr));
        buf.clear();
      }
      curr = marks[i];
      buf.write(chars[i]);
    }
    if (curr != null) {
      result.add(DiffSpan(buf.toString(), curr));
    }
    return result;
  }
}

extension _Characters on String {
  /// 按 Dart 的 UTF-16 code unit 切会拆坏 emoji/组合字符，这里按 rune 切。
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
