import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/common/json_splitter.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('jsonsplitter'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<JsonSplitter> split(String content) async {
    final file = File('${tmp.path}/index.json');
    file.writeAsBytesSync(utf8.encode(content));
    final splitter = JsonSplitter(outDir: '${tmp.path}/out');
    final ok = await splitter.split(file);
    expect(ok, true, reason: 'split should succeed for: $content');
    return splitter;
  }

  test('课堂内容进 head，b 的每个元素单独落盘', () async {
    final s = await split('{"s":"a","r":"http://x/y","b":[{"i":1},{"i":2}],"n":3}');

    expect(s.head, {'s': 'a', 'r': 'http://x/y', 'n': 3});
    expect(s.elementPaths.length, 2);
    expect(jsonDecode(File(s.elementPaths[0]).readAsStringSync()), {'i': 1});
    expect(jsonDecode(File(s.elementPaths[1]).readAsStringSync()), {'i': 2});
  });

  test('b 在最前面也认', () async {
    final s = await split('{"b":[{"i":1}],"s":"a"}');
    expect(s.head, {'s': 'a'});
    expect(s.elementPaths.length, 1);
  });

  test('空数组', () async {
    final s = await split('{"s":"a","b":[]}');
    expect(s.head, {'s': 'a'});
    expect(s.elementPaths, isEmpty);
  });

  test('字符串里的括号、逗号、转义引号不会把结构扫乱', () async {
    const tricky = r'{"desc":"a{b}c[d],e\"f\\","b":[{"t":"}]{[\",","u":"x"},{"t":"ok"}],"z":1}';
    final s = await split(tricky);

    expect(s.head, {'desc': r'a{b}c[d],e"f\', 'z': 1});
    expect(s.elementPaths.length, 2);
    expect(jsonDecode(File(s.elementPaths[0]).readAsStringSync()), {'t': '}]{[",', 'u': 'x'});
    expect(jsonDecode(File(s.elementPaths[1]).readAsStringSync()), {'t': 'ok'});
  });

  test('多字节 UTF-8 原样带走，不会被拆坏', () async {
    final s = await split('{"name":"课堂一","b":[{"n":"第一课 — 你好，世界 🎧"}]}');

    expect(s.head, {'name': '课堂一'});
    expect(
      jsonDecode(File(s.elementPaths[0]).readAsStringSync()),
      {'n': '第一课 — 你好，世界 🎧'},
    );
  });

  test('元素内部嵌套很深也能原样切出来', () async {
    final book = {
      'book': {'i': 7, 'n': '书'},
      'd': [
        {'u': '.mp3', 'h': 'abc'},
      ],
      'c': [
        {
          'i': 1,
          'v': [
            {'i': 10, 'q': '问', 'a': '答'},
            {'i': 11, 'q': 'x'},
          ],
        },
      ],
    };
    final s = await split(jsonEncode({'s': 'v', 'b': [book], 'r': 'u'}));

    expect(s.head, {'s': 'v', 'r': 'u'});
    expect(jsonDecode(File(s.elementPaths[0]).readAsStringSync()), book);
  });

  test('元素大于一次 flush 的阈值也不会丢字节', () async {
    final big = {'q': 'x' * (1 << 18)};
    final s = await split(jsonEncode({'b': [big, big]}));

    expect(s.elementPaths.length, 2);
    expect(jsonDecode(File(s.elementPaths[0]).readAsStringSync()), big);
    expect(jsonDecode(File(s.elementPaths[1]).readAsStringSync()), big);
  });

  test('缩进过的 JSON 也认', () async {
    final s = await split(const JsonEncoder.withIndent('  ').convert({
      's': 'a',
      'b': [
        {'i': 1},
        {'i': 2},
      ],
    }));

    expect(s.head, {'s': 'a'});
    expect(s.elementPaths.length, 2);
    expect(jsonDecode(File(s.elementPaths[1]).readAsStringSync()), {'i': 2});
  });

  test('没有 b 数组返回 false', () async {
    final file = File('${tmp.path}/index.json');
    file.writeAsStringSync('{"s":"a"}');
    final splitter = JsonSplitter(outDir: '${tmp.path}/out');
    expect(await splitter.split(file), false);
  });

  test('b 里是裸标量返回 false', () async {
    final file = File('${tmp.path}/index.json');
    file.writeAsStringSync('{"b":[1,2]}');
    final splitter = JsonSplitter(outDir: '${tmp.path}/out');
    expect(await splitter.split(file), false);
  });

  test('文件在元素中间截断返回 false', () async {
    final file = File('${tmp.path}/index.json');
    file.writeAsStringSync('{"b":[{"i":1},{"i":');
    final splitter = JsonSplitter(outDir: '${tmp.path}/out');
    expect(await splitter.split(file), false);
  });
}
