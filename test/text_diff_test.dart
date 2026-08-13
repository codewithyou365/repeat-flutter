import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/common/text_diff.dart';

/// 把标了 diff 的片段按顺序拼出来，方便断言
List<String> diffTexts(List<DiffSpan> spans) {
  return spans.where((e) => e.mark == DiffMark.diff).map((e) => e.text).toList();
}

/// 分段拼回去必须还是原文，一个字符都不能丢
void expectLossless(List<DiffSpan> spans, String raw) {
  expect(spans.map((e) => e.text).join(), raw);
}

void main() {
  const all = TextDiffOptions(ignoreSpace: true, ignorePunctuation: true, ignoreCase: true, ignoreNumber: true);
  const none = TextDiffOptions(ignoreSpace: false, ignorePunctuation: false, ignoreCase: false, ignoreNumber: false);

  group('TextDiff.compare', () {
    test('完全一样', () {
      final r = TextDiff.compare('hello world', 'hello world', none);
      expect(r.same, true);
      expect(r.diffCount, 0);
      expect(diffTexts(r.expected), isEmpty);
      expect(diffTexts(r.actual), isEmpty);
    });

    test('默认配置下大小写/标点/空格差异不算错', () {
      final r = TextDiff.compare('The quick, brown fox.', 'the quick brown   fox', const TextDiffOptions());
      expect(r.same, true, reason: '默认忽略空格、标点、大小写');
    });

    test('关掉忽略大小写后就算错', () {
      final r = TextDiff.compare('The fox', 'the fox', const TextDiffOptions(ignoreCase: false));
      expect(r.same, false);
      expect(diffTexts(r.expected), ['T']);
      expect(diffTexts(r.actual), ['t']);
      expect(r.diffCount, 1);
    });

    test('关掉忽略标点后就算错', () {
      final r = TextDiff.compare('fox.', 'fox', const TextDiffOptions(ignorePunctuation: false));
      expect(r.same, false);
      expect(diffTexts(r.expected), ['.']);
      expect(diffTexts(r.actual), isEmpty);
    });

    test('关掉忽略空格后就算错', () {
      final r = TextDiff.compare('a b', 'ab', const TextDiffOptions(ignoreSpace: false));
      expect(r.same, false);
      expect(diffTexts(r.expected), [' ']);
    });

    test('忽略数字：开则不算错，关则算错', () {
      expect(TextDiff.compare('room 101', 'room 202', const TextDiffOptions(ignoreNumber: true)).same, true);
      expect(TextDiff.compare('room 101', 'room 202', const TextDiffOptions(ignoreNumber: false)).same, false);
    });

    test('漏词：答案里标红，输入里没有多余', () {
      final r = TextDiff.compare('the quick brown fox', 'the quick fox', all);
      expect(r.same, false);
      expect(diffTexts(r.expected), ['brown']);
      expect(diffTexts(r.actual), isEmpty);
      expect(r.diffCount, 1);
      expectLossless(r.expected, 'the quick brown fox');
      expectLossless(r.actual, 'the quick fox');
    });

    test('多词：输入里标红，答案里没有缺失', () {
      final r = TextDiff.compare('the fox', 'the quick fox', all);
      expect(r.same, false);
      expect(diffTexts(r.expected), isEmpty);
      expect(diffTexts(r.actual), ['quick']);
      expect(r.diffCount, 1);
    });

    test('拼错一个字母：只标那个字母，算一处', () {
      final r = TextDiff.compare('the lazy dog', 'the lasy dog', all);
      expect(diffTexts(r.expected), ['z']);
      expect(diffTexts(r.actual), ['s']);
      expect(r.diffCount, 1);
    });

    test('多处差异分别计数', () {
      final r = TextDiff.compare('abc def ghi', 'abX def gYi', all);
      expect(r.diffCount, 2);
    });

    test('中文逐字', () {
      final r = TextDiff.compare('今天天气很好', '今天天气不好', all);
      expect(diffTexts(r.expected), ['很']);
      expect(diffTexts(r.actual), ['不']);
      expect(r.diffCount, 1);
    });

    test('输入为空：整段答案标红', () {
      final r = TextDiff.compare('hello', '', all);
      expect(r.same, false);
      expect(diffTexts(r.expected), ['hello']);
      expect(r.actual, isEmpty);
    });

    test('两边都空算一致', () {
      final r = TextDiff.compare('', '', all);
      expect(r.same, true);
    });

    test('只剩被忽略的字符，等于两边都空', () {
      final r = TextDiff.compare('  ,  ', '', all);
      expect(r.same, true);
      expectLossless(r.expected, '  ,  ');
    });

    test('emoji 不会被拆坏', () {
      final r = TextDiff.compare('go 🚀 now', 'go 🚀 now', all);
      expect(r.same, true);
      expectLossless(r.expected, 'go 🚀 now');
    });

    test('超长文本走退化分支，不做 LCS', () {
      final long = 'a' * (TextDiff.maxLenForLcs + 10);
      expect(TextDiff.compare(long, long, none).same, true);
      final r = TextDiff.compare(long, '${long}b', none);
      expect(r.same, false);
      expect(r.diffCount, 1);
      expectLossless(r.actual, '${long}b');
    });
  });
}
