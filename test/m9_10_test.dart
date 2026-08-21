import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/db/migration/m9_10.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

VerseMigrationTo10? run(Map<String, dynamic> old) => migrateVerseContentTo10(jsonEncode(old));

Map<String, dynamic>? migrate(Map<String, dynamic> old) {
  final ret = run(old);
  return ret == null ? null : jsonDecode(ret.content) as Map<String, dynamic>;
}

void main() {
  test('平铺 key 搬进 q/a/t 三个块，其余 key 原样保留', () {
    final m = migrate({
      'q': 'question',
      'qStart': '00:00:01,000',
      'qEnd': '00:00:02,000',
      'a': 'answer',
      'aStart': '00:00:03,000',
      'aEnd': '00:00:04,000',
      'aDownload': {'u': 'x.mp3', 'h': 'abhash'},
      'aShowType': 'audio',
      'n': 'note',
      's': 'video',
      'd': [
        {'u': 'y.mp4', 'h': 'cdhash'}
      ],
    })!;

    expect(m['q'], {'text': 'question', 'start': '00:00:01,000', 'end': '00:00:02,000'});
    expect(m['a'], {
      'text': 'answer',
      'start': '00:00:03,000',
      'end': '00:00:04,000',
      'showType': 'audio',
      'mediaHash': 'abhash',
    });
    // 这一节本来就有 'd'，文件对象追加进去（整节媒体仍是第一项）
    expect(m['d'], [
      {'u': 'y.mp4', 'h': 'cdhash'},
      {'u': 'x.mp3', 'h': 'abhash'},
    ]);
    // 笔记仍然平铺，整节的 's'/'d' 不动。
    expect(m['n'], 'note');
    expect(m['s'], 'video');
    expect(m.containsKey('aStart'), false);
    expect(m.containsKey('aShowType'), false);

    // 迁完的内容能被现在的模型读出来。
    final c = VerseContent.fromJson(m);
    expect(c.answer, 'answer');
    expect(c.answerShowType, 'audio');
    expect(c.answerEnd, '00:00:04,000');
    expect(c.answerMediaHash, 'abhash');
    expect(c.note, 'note');
    expect(c.question, 'question');
  });

  test('字幕导入的 tip 归位到 t 的正文', () {
    final m = migrate({'a': 'answer', 'tip': 'hint'})!;
    expect(m['t'], {'text': 'hint'});
    expect(m.containsKey('tip'), false);
  });

  test('已经是新格式的行不动', () {
    expect(
      migrate({
        'a': {'text': 'answer', 'start': '00:00:03,000'},
        'n': 'note',
      }),
      null,
    );
  });

  test('新旧混在一起时，已有的新块优先，平铺 key 只补空缺', () {
    final m = migrate({
      'a': {'text': 'new answer'},
      'aStart': '00:00:03,000',
    })!;
    expect(m['a'], {'text': 'new answer', 'start': '00:00:03,000'});
  });

  test('没有 d 的节，字段媒体交给 book 登记', () {
    final ret = run({
      'a': 'answer',
      'aDownload': {'u': 'x.mp3', 'h': 'abhash'},
    })!;
    final m = jsonDecode(ret.content) as Map<String, dynamic>;
    expect(m['a'], {'text': 'answer', 'mediaHash': 'abhash'});
    // 不能凭空给这一节造一个 'd'，否则整节媒体会被顶成这个文件
    expect(m.containsKey('d'), false);
    expect(ret.bookMedia, [
      {'u': 'x.mp3', 'h': 'abhash'}
    ]);
  });

  test('中间那一版内嵌的 download 也收成 mediaHash', () {
    final ret = run({
      'a': {'text': 'answer', 'download': {'u': '.wav', 'h': 'wavhash'}, 'showType': 'audio'},
      'd': [
        {'u': '.mp4', 'h': 'sectionhash'}
      ],
    })!;
    final m = jsonDecode(ret.content) as Map<String, dynamic>;
    expect(m['a'], {'text': 'answer', 'showType': 'audio', 'mediaHash': 'wavhash'});
    expect(m['d'], [
      {'u': '.mp4', 'h': 'sectionhash'},
      {'u': '.wav', 'h': 'wavhash'},
    ]);
  });

  test('内容坏了或者没有这三个字段就不动', () {
    expect(migrateVerseContentTo10('not json'), null);
    expect(migrateVerseContentTo10('[]'), null);
    expect(migrate({'n': 'note'}), null);
  });
}
