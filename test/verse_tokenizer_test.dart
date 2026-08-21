import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/search/verse_tokenizer.dart';

void main() {
  group('tokenize', () {
    test('pure chinese is cut into bigrams', () {
      expect(VerseTokenizer.tokenize('世界和平'), ['世界', '界和', '和平']);
    });

    test('single chinese char keeps itself', () {
      expect(VerseTokenizer.tokenize('我'), ['我']);
    });

    test('latin is lowercased, digits are a separate run', () {
      expect(VerseTokenizer.tokenize('Hello 世界123'), ['hello', '世界', '123']);
    });

    test('punctuation and emoji are separators', () {
      expect(VerseTokenizer.tokenize('a,b。c 🙂d'), ['a', 'b', 'c', 'd']);
    });

    test('empty in, empty out', () {
      expect(VerseTokenizer.tokenize(''), <String>[]);
    });
  });

  group('buildIndexText', () {
    test('joins fields and skips null/empty', () {
      expect(
        VerseTokenizer.buildIndexText(['世界和平', null, '', 'Hi']),
        '世界 界和 和平 hi',
      );
    });
  });

  group('buildMatchQuery', () {
    test('joins tokens with AND and quotes them', () {
      expect(VerseTokenizer.buildMatchQuery('世界 hello'), '"世界" AND "hello"');
    });

    test('fts5 syntax chars in the input are neutralized', () {
      // * : - ^ 都不是 token 字符，直接被当成分隔符丢掉
      expect(VerseTokenizer.buildMatchQuery('ab* OR -c'), '"ab" AND "or" AND "c"');
    });

    test('is case-insensitive: query matches index regardless of case', () {
      // 索引侧和查询侧都小写，所以大小写怎么写都能对上
      expect(VerseTokenizer.buildIndexText(['Hello World']), 'hello world');
      expect(VerseTokenizer.buildMatchQuery('HELLO'), '"hello"');
      expect(VerseTokenizer.buildMatchQuery('hello'), '"hello"');
      expect(VerseTokenizer.buildMatchQuery('HeLLo'), '"hello"');
    });

    test('returns null when nothing is tokenizable', () {
      expect(VerseTokenizer.buildMatchQuery('  ,。*  '), null);
    });
  });
}
