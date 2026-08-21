import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

void main() {
  test('字段引用串的拆解', () {
    expect(VerseField.ref('t', 0), 't');
    expect(VerseField.ref('t', 2), 't2');
    expect(VerseField.baseOf('t'), 't');
    expect(VerseField.baseOf('t12'), 't');
    expect(VerseField.indexOf('t'), 0);
    expect(VerseField.indexOf('t12'), 12);
    expect(VerseField.indexOf('q'), 0);
  });

  test('读写按下标落到数组的对应那一条', () {
    final m = <String, dynamic>{};
    VerseField.setText(m, 't', 'first');
    VerseField.setText(m, 't2', 'third');
    // 中间那条没写内容，但必须占着位置，否则第 3 条会变成第 2 条。
    expect(m['t'], [
      {'text': 'first'},
      <String, dynamic>{},
      {'text': 'third'},
    ]);
    expect(VerseField.getText(m, 't'), 'first');
    expect(VerseField.getText(m, 't1'), null);
    expect(VerseField.getText(m, 't2'), 'third');
    expect(VerseField.tipLength(m), 3);
  });

  test('清空中间那条只留空块，末尾的才截掉', () {
    final m = <String, dynamic>{
      't': [
        {'text': 'first'},
        {'text': 'second'},
        {'text': 'third'},
      ]
    };
    VerseField.setText(m, 't1', null);
    expect(m['t'], [
      {'text': 'first'},
      <String, dynamic>{},
      {'text': 'third'},
    ]);
    VerseField.setText(m, 't2', null);
    // 末尾连着两条空的一起截掉
    expect(m['t'], [
      {'text': 'first'}
    ]);
    VerseField.setText(m, 't', null);
    expect(m.containsKey('t'), false);
  });

  test('还没迁移的 map 形态当成第 1 条', () {
    final m = <String, dynamic>{
      't': {'text': 'hint'}
    };
    expect(VerseField.getText(m, 't'), 'hint');
    expect(VerseField.getText(m, 't1'), null);
    // 写第 2 条时就地包成数组，第 1 条保住
    VerseField.setText(m, 't1', 'second');
    expect(m['t'], [
      {'text': 'hint'},
      {'text': 'second'},
    ]);
  });

  test('tipCount 取 verse/book 里长的那个，上限 8', () {
    expect(VerseField.tipCount(null, null), 1);
    expect(
      VerseField.tipCount({
        't': [{}, {}]
      }, {
        't': [{}]
      }),
      2,
    );
    expect(VerseField.tipCount({'t': List.generate(20, (_) => {})}, null), VerseField.maxTip);
  });

  test('lookup 按同一个下标逐层对齐', () {
    final verse = <String, dynamic>{
      't': [
        {'text': 'v0'},
        {'text': 'v1'},
      ]
    };
    final book = <String, dynamic>{
      't': [
        {'mediaHash': 'b0'},
        {'mediaHash': 'b1'},
      ]
    };
    expect(VerseField.lookup([verse, book], 't1', VerseField.mediaHash), 'b1');
    expect(VerseField.lookup([verse, book], 't', VerseField.mediaHash), 'b0');
  });

  test('q/a 不受影响，n 仍然是平铺的字符串', () {
    final m = <String, dynamic>{};
    VerseField.setText(m, 'q', 'question');
    VerseField.setText(m, 'n', 'note');
    expect(m['q'], {'text': 'question'});
    expect(m['n'], 'note');
  });

  test('VerseContent 往返不丢提示', () {
    final json = <String, dynamic>{
      'k': 'key',
      't': [
        {'text': 'first'},
        <String, dynamic>{},
        {'text': 'third', 'start': '00:00:01,000'},
      ],
    };
    final ret = VerseContent.fromJson(json).toJson();
    expect(ret['t'], [
      {'text': 'first'},
      <String, dynamic>{},
      {'text': 'third', 'start': '00:00:01,000'},
    ]);
  });

  group('整节媒体（顶层 m）', () {
    Map<String, dynamic> d(String hash) => {'u': '.mp3', 'h': hash};

    test('m 就近取，文件对象跨层找：一节自己有 d 也遮蔽不掉章节的整节媒体', () {
      // 章节声明整节媒体是 chapterMedia；这一节因为扩展助手给答案生成了音频，
      // 自己长出了一个 'd'。旧规则（就近那一层 d 的第一项）会把整节媒体错认成 answerAudio。
      final verse = <String, dynamic>{
        'd': [d('answerAudio')],
        'a': {'mediaHash': 'answerAudio'},
      };
      final chapter = <String, dynamic>{
        'd': [d('chapterMedia')],
        'm': 'chapterMedia',
      };
      final levels = <Map<String, dynamic>?>[verse, chapter, null];

      expect(VerseField.findSectionDownload(levels)?.hash, 'chapterMedia');
      // 字段专属媒体仍然压过整节媒体
      expect(VerseField.findDownloadByHash(levels, 'answerAudio')?.hash, 'answerAudio');
    });

    test('这一节自己换了整节媒体时，verse 的 m 压过 chapter 的', () {
      final verse = <String, dynamic>{
        'd': [d('verseMedia')],
        'm': 'verseMedia',
      };
      final chapter = <String, dynamic>{
        'd': [d('chapterMedia')],
        'm': 'chapterMedia',
      };
      expect(VerseField.findSectionDownload([verse, chapter, null])?.hash, 'verseMedia');
    });

    test('没有 m 的老内容回落到就近那一层 d 的第一项', () {
      final verse = <String, dynamic>{};
      final chapter = <String, dynamic>{
        'd': [d('first'), d('second')],
      };
      expect(VerseField.findSectionDownload([verse, chapter, null])?.hash, 'first');
    });

    test('m 指向的文件已经不在任何 d 里时，回落而不是返回 null', () {
      final chapter = <String, dynamic>{
        'd': [d('stillHere')],
        'm': 'deletedLongAgo',
      };
      expect(VerseField.findSectionDownload([null, chapter, null])?.hash, 'stillHere');
    });

    test('ensureSectionMediaHash 只补一次，已有 m 不覆盖', () {
      final m = <String, dynamic>{
        'd': [d('first'), d('second')],
      };
      expect(VerseField.ensureSectionMediaHash(m), true);
      expect(m['m'], 'first');
      expect(VerseField.ensureSectionMediaHash(m), false);

      // 没有 d 的一层不该凭空造出 m
      final empty = <String, dynamic>{};
      expect(VerseField.ensureSectionMediaHash(empty), false);
      expect(empty.containsKey('m'), false);
    });

    test('setSectionMedia 换整节媒体时保留字段专属媒体', () {
      final verse = <String, dynamic>{
        'd': [d('oldSection'), d('answerAudio')],
        'm': 'oldSection',
        'a': {'mediaHash': 'answerAudio'},
      };
      VerseField.setSectionMedia(verse, DownloadContent(url: '.mp4', hash: 'newSection'));

      expect(verse['m'], 'newSection');
      expect((verse['d'] as List).map((e) => e['h']), ['newSection', 'oldSection', 'answerAudio']);
      // 答案那份音频还在，字段块里的 mediaHash 没有变成悬空引用
      expect(VerseField.findDownloadByHash([verse], 'answerAudio')?.hash, 'answerAudio');
    });

    test('setMedia 一律登记到这一节自己的 d', () {
      final verse = <String, dynamic>{};
      VerseField.setMedia(verse: verse, acronym: 'a', d: DownloadContent(url: '.mp3', hash: 'answerAudio'));

      expect((verse['d'] as List).single['h'], 'answerAudio');
      expect(VerseField.getStr(verse, 'a', VerseField.mediaHash), 'answerAudio');
    });
  });

  group('内容数组（content）', () {
    test('没有 content 时回落到老的 text，一项正文', () {
      final m = <String, dynamic>{
        'a': {'text': '老答案'},
        'n': '笔记',
      };
      expect(VerseField.getText(m, 'a'), '老答案');
      expect(VerseField.getItems(m, 'a').single.text, '老答案');
      // 'n' 是平铺的裸串，没有字段块，一样能当成一项正文读出来
      expect(VerseField.getItems(m, 'n').single.text, '笔记');
      expect(VerseField.getItems(m, 'q'), isEmpty);
    });

    test('纯正文只拼裸字符串项，文件项跳过', () {
      final m = <String, dynamic>{
        'a': {
          'content': [
            '第一段',
            {'h': 'aaa'},
            '第二段',
          ]
        }
      };
      expect(VerseField.getText(m, 'a'), '第一段\n第二段');
      final items = VerseField.getItems(m, 'a');
      expect(items.length, 3);
      expect(items[0].isText, true);
      expect(items[1].isText, false);
      expect(items[1].hash, 'aaa');
      expect(items[2].text, '第二段');
    });

    test('认不出来的项直接跳过，不让整个字段消失', () {
      final m = <String, dynamic>{
        'a': {
          'content': [
            '正文',
            {'h': ''},
            {'nothing': 1},
            42,
            null,
            {'h': 'ok', 'height': 0.5},
          ]
        }
      };
      final items = VerseField.getItems(m, 'a');
      expect(items.length, 2);
      expect(items[0].text, '正文');
      expect(items[1].hash, 'ok');
      expect(items[1].height, 0.5);
    });

    test('setText 换掉全部字符串项，文件项留在原位', () {
      final m = <String, dynamic>{
        'a': {
          'content': [
            {'h': 'img'},
            '旧的第一段',
            '旧的第二段',
          ]
        }
      };
      VerseField.setText(m, 'a', '新答案');
      // 图还在最前面，两段旧正文合成一段新的插回原来第一段的位置
      expect(m['a']['content'], [
        {'h': 'img'},
        '新答案',
      ]);
    });

    test('setText 清空正文时文件项还在', () {
      final m = <String, dynamic>{
        'a': {
          'content': [
            '正文',
            {'h': 'img'},
          ]
        }
      };
      VerseField.setText(m, 'a', null);
      expect(m['a']['content'], [
        {'h': 'img'}
      ]);
      expect(VerseField.getText(m, 'a'), null);
    });

    test('最后一项也没了就把 content 连同空字段块一起清掉', () {
      final m = <String, dynamic>{
        'a': {'content': ['正文']}
      };
      VerseField.setText(m, 'a', null);
      expect(m.containsKey('a'), false);
    });

    test('setItems 往返，并把升级前的死 text 删掉', () {
      // 真实数据是 jsonDecode 出来的，内层一律是 Map<String, dynamic>
      final m = <String, dynamic>{
        'a': <String, dynamic>{'text': '老答案', 'start': '00:00:00,000'},
      };
      VerseField.setItems(m, 'a', [
        const VerseContentItem.text('正文'),
        const VerseContentItem.file('web', height: 0.5),
      ]);
      expect(m['a'], {
        'start': '00:00:00,000',
        'content': [
          '正文',
          {'h': 'web', 'height': 0.5},
        ],
      });
      expect(VerseField.getText(m, 'a'), '正文');

      VerseField.setItems(m, 'a', []);
      expect(m['a'], {'start': '00:00:00,000'});
    });

    test('加内容项只往 d 末尾追加，不顶掉没有 m 的老内容的整节媒体', () {
      // 没有 'm' 的老内容按 'd' 第一项算整节媒体（findSectionDownload 的回落），
      // 给某个字段配图/配网页时把文件插到前面会把整节的音视频换掉。
      final verse = <String, dynamic>{
        'd': [
          {'u': 'a.mp3', 'h': 'audio1'}
        ],
      };
      expect(VerseField.findSectionDownload([verse])!.hash, 'audio1');

      VerseField.addDownload(verse, DownloadContent(url: 'i.png', hash: 'img1'));
      VerseField.setItems(verse, 'a', [const VerseContentItem.file('img1')]);

      expect(VerseField.findSectionDownload([verse])!.hash, 'audio1');
      expect((verse['d'] as List).map((e) => e['h']), ['audio1', 'img1']);
      // 内容项写的是 'content'，跟字段媒体的 'mediaHash' 各走各的
      expect(VerseField.getStr(verse, 'a', VerseField.mediaHash), isNull);
    });

    test('数组字段（提示）一样能用内容数组', () {
      final m = <String, dynamic>{};
      VerseField.setItems(m, 't1', [const VerseContentItem.text('第二条提示')]);
      expect(m['t'], [
        <String, dynamic>{},
        {
          'content': ['第二条提示']
        },
      ]);
      expect(VerseField.getText(m, 't1'), '第二条提示');
      expect(VerseField.getText(m, 't'), null);
    });
  });

  group('内容数组的行内标记', () {
    test('往返', () {
      const items = [
        VerseContentItem.text('第一段\n还是第一段'),
        VerseContentItem.file('h1'),
        VerseContentItem.file('h2', height: 0.5),
        VerseContentItem.text('第二段'),
      ];
      const str = '第一段\n还是第一段\n[[f:h1]]\n[[f:h2,h=0.5]]\n第二段';
      expect(VerseContentMarkup.encode(items), str);

      final back = VerseContentMarkup.decode(str);
      expect(back.length, 4);
      expect(back[0].text, '第一段\n还是第一段');
      expect(back[1].hash, 'h1');
      expect(back[2].hash, 'h2');
      expect(back[2].height, 0.5);
      expect(back[3].text, '第二段');
    });

    test('只有整行才算标记，正文里提到这个写法不受影响', () {
      final items = VerseContentMarkup.decode('这里讲的是 [[f:h1]] 这种写法');
      expect(items.single.text, '这里讲的是 [[f:h1]] 这种写法');
    });

    test('每段首尾的空行丢掉，中间的留着当排版', () {
      final items = VerseContentMarkup.decode('\n\n第一行\n\n第三行\n\n[[f:h1]]\n\n');
      expect(items.length, 2);
      expect(items[0].text, '第一行\n\n第三行');
      expect(items[1].hash, 'h1');
    });

    test('空文本解析成一项都没有', () {
      expect(VerseContentMarkup.decode(''), isEmpty);
      expect(VerseContentMarkup.decode('   \n  '), isEmpty);
    });
  });

  group('正文区顺序（o）', () {
    test('不写就是默认顺序', () {
      expect(VerseField.orderOf([<String, dynamic>{}, null]), ['q', 'a']);
    });

    test('就近取第一个写了 o 的层', () {
      final verse = <String, dynamic>{
        'o': ['a', 'q']
      };
      final chapter = <String, dynamic>{
        'o': ['q', 'a']
      };
      expect(VerseField.orderOf([verse, chapter]), ['a', 'q']);
      expect(VerseField.orderOf([null, chapter]), ['q', 'a']);
    });

    test('只管顺序不管有无：漏写的补在后面，不认识的丢掉', () {
      final m = <String, dynamic>{
        'o': ['a', 'zzz', 'a']
      };
      // 'a' 提到了就排前面，重复的忽略，'zzz' 不认识丢掉，'q' 漏写了补在后面
      expect(VerseField.orderOf([m]), ['a', 'q']);
    });
  });

  group('生成指令（ins）', () {
    test('新内容存在字段块里，跟正文分开', () {
      final m = <String, dynamic>{};
      VerseField.setText(m, 'a', '生成出来的答案');
      VerseField.setInstruction(m, 'a', '把问题翻译成中文');
      expect(VerseField.getText(m, 'a'), '生成出来的答案');
      expect(VerseField.getInstruction(m, 'a'), '把问题翻译成中文');

      VerseField.setInstruction(m, 'a', null);
      expect(VerseField.getInstruction(m, 'a'), null);
      expect(VerseField.getText(m, 'a'), '生成出来的答案');
    });

    test('老数据还是从正文末尾拆', () {
      final m = <String, dynamic>{};
      VerseField.setText(m, 'a', VerseField.embedInstruction('答案', '老指令'));
      expect(VerseField.getInstruction(m, 'a'), '老指令');
    });
  });
}
