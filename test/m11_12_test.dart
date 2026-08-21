import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/db/migration/m11_12.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

Map<String, dynamic>? verse(Map<String, dynamic> old) {
  final ret = migrateVerseContentTo12(jsonEncode(old));
  return ret == null ? null : jsonDecode(ret) as Map<String, dynamic>;
}

Map<String, dynamic>? book(Map<String, dynamic> old) {
  final ret = migrateBookContentTo12(jsonEncode(old));
  return ret == null ? null : jsonDecode(ret) as Map<String, dynamic>;
}

void main() {
  group('verse/chapter', () {
    test('t 那一块包进数组，其余 key 不动', () {
      final m = verse({
        'q': {'text': 'question'},
        't': {'text': 'hint', 'start': '00:00:01,000'},
        'n': 'note',
      })!;
      expect(m['t'], [
        {'text': 'hint', 'start': '00:00:01,000'}
      ]);
      expect(m['q'], {'text': 'question'});
      expect(m['n'], 'note');
    });

    test('已经是数组、或者压根没有 t，都不动', () {
      expect(
        verse({
          't': [
            {'text': 'hint'}
          ]
        }),
        null,
      );
      expect(verse({'q': {'text': 'question'}}), null);
      expect(migrateVerseContentTo12('not json'), null);
      expect(migrateVerseContentTo12('[]'), null);
    });

    test('迁完的内容能被现在的模型读出来', () {
      final m = verse({
        't': {'text': 'hint', 'mediaHash': 'h1', 'showType': 'audio'},
      })!;
      final c = VerseContent.fromJson(m);
      expect(c.tips.length, 1);
      expect(c.tips[0].text, 'hint');
      expect(c.tips[0].mediaHash, 'h1');
      expect(c.tip, 'hint');
      expect(VerseField.getText(m, 't'), 'hint');
    });
  });

  group('book', () {
    test('提示服务配置下放到各字段块，t 变数组', () {
      final m = book({
        'a': {'fontSize': '18'},
        't': {
          'fontSize': '14',
          'fontAlias': 'x.ttf',
          'q': {'h': 'qhash', 'k': 'qkey', 's': 'qsvc', 'i': 3},
          'a': {'h': 'ahash'},
          't': {'h': 'thash', 'k': 'tkey', 'n': '词源'},
          'n': {'h': 'nhash'},
        },
      })!;

      // q 本来没有字段块，直接建一个；a 已有字体块，配置并进去。
      expect(m['q'], {'h': 'qhash', 'k': 'qkey', 's': 'qsvc', 'i': 3});
      expect(m['a'], {'fontSize': '18', 'h': 'ahash'});
      expect(m['n'], {'h': 'nhash'});
      // 提示自己的配置跟提示字体合成第 1 条。
      expect(m['t'], [
        {'fontSize': '14', 'fontAlias': 'x.ttf', 'h': 'thash', 'k': 'tkey', 'n': '词源'}
      ]);
      // 名字能按下标读出来。
      expect(VerseField.tipNameOf(m, 0), '词源');
      expect(VerseField.getStr(m, 't', VerseField.fontSize), '14');
    });

    test('只有字体没有提示配置时也照样变数组', () {
      final m = book({
        't': {'fontSize': '20'},
      })!;
      expect(m['t'], [
        {'fontSize': '20'}
      ]);
    });

    test('已经是数组、或者压根没有 t，都不动', () {
      expect(
        book({
          't': [
            {'fontSize': '20'}
          ]
        }),
        null,
      );
      expect(book({'q': {'fontSize': '18'}}), null);
    });
  });
}
