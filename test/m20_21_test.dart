import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/db/migration/m20_21.dart';

/// 迁移里搬文件的那一步。数据库那一步（删 classroomResourceVersion）没什么好测的。
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('m20_21_');
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  Future<void> write(String relativePath, String content) async {
    final file = File('${root.path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<String?> read(String relativePath) async {
    final file = File('${root.path}/$relativePath');
    return await file.exists() ? await file.readAsString() : null;
  }

  Future<void> migrate() => migrateFilesTo21(root);

  test('书本目录和 g 目录都并进 f，老目录删掉', () async {
    await write('1/4/ab/1111.mp3', 'book4-media');
    await write('1/7/cd/2222.mp4', 'book7-media');
    await write('1/g/ef/3333.zip', 'game-zip');
    await write('1/g/ef/3333/index.html', 'game-unzipped');

    await migrate();

    expect(await read('1/f/ab/1111.mp3'), 'book4-media');
    expect(await read('1/f/cd/2222.mp4'), 'book7-media');
    expect(await read('1/f/ef/3333.zip'), 'game-zip');
    // 解压目录整个搬过去，不用删了重解压
    expect(await read('1/f/ef/3333/index.html'), 'game-unzipped');

    expect(await Directory('${root.path}/1/4').exists(), false);
    expect(await Directory('${root.path}/1/7').exists(), false);
    expect(await Directory('${root.path}/1/g').exists(), false);
  });

  test('同一个 hash 被两本书引用：撞名的丢一份，内容不丢', () async {
    await write('1/4/ab/1111.mp3', 'same-content');
    await write('1/7/ab/1111.mp3', 'same-content');
    await write('1/7/ab/9999.mp3', 'only-in-book7');

    await migrate();

    expect(await read('1/f/ab/1111.mp3'), 'same-content');
    // 同一个分桶目录下的另一个文件不能被前一本书的 rename 顺手覆盖掉
    expect(await read('1/f/ab/9999.mp3'), 'only-in-book7');
  });

  test('书本目录里的导入导出临时产物不搬走', () async {
    await write('1/4/index.json', '{}');
    await write('1/4/__root.json', '{}');
    await write('1/4/1_4.zip', 'zip');
    await write('1/4/ab/1111.mp3', 'media');

    await migrate();

    expect(await read('1/f/ab/1111.mp3'), 'media');
    expect(await read('1/f/index.json'), null);
    expect(await read('1/f/__root.json'), null);
    expect(await read('1/f/1_4.zip'), null);
  });

  test('导入暂存目录删掉，非课堂目录不碰', () async {
    await write('1/__import/books/0.json', '{}');
    await write('1/4/ab/1111.mp3', 'media');
    await write('_import_tmp/whatever.db', 'db');

    await migrate();

    expect(await Directory('${root.path}/1/__import').exists(), false);
    expect(await read('1/f/ab/1111.mp3'), 'media');
    expect(await read('_import_tmp/whatever.db'), 'db');
  });

  test('已经迁移过一遍再跑一次不出错，f 里的东西原样', () async {
    await write('1/4/ab/1111.mp3', 'media');

    await migrate();
    await migrate();

    expect(await read('1/f/ab/1111.mp3'), 'media');
  });

  test('moveMerge：目标已存在时逐项合并，子目录也合并', () async {
    await write('from/x.txt', 'x');
    await write('from/sub/y.txt', 'y');
    await write('to/z.txt', 'z');
    await write('to/sub/w.txt', 'w');

    await moveMerge(Directory('${root.path}/from'), Directory('${root.path}/to'));

    expect(await read('to/x.txt'), 'x');
    expect(await read('to/z.txt'), 'z');
    expect(await read('to/sub/y.txt'), 'y');
    expect(await read('to/sub/w.txt'), 'w');
    expect(await Directory('${root.path}/from').exists(), false);
  });
}
