import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:repeat_flutter/logic/content_web_server.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

void main() {
  late Directory tmp;
  late String root;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('content_web_');
    root = p.join(tmp.path, 'files');
    Directory(root).createSync(recursive: true);
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('请求路径不能跑出根目录', () {
    test('正常路径解析到根目录下', () {
      final f = ContentWebServer.resolveWithin(root, '/ab/cdef/index.html');
      expect(f, isNotNull);
      expect(p.isWithin(root, f!.path), true);
    });

    test('../ 爬出去的一律拒掉', () {
      for (var path in [
        '/../secret.txt',
        '/ab/../../secret.txt',
        '/../../../../../../etc/passwd',
        '/ab/./../../secret.txt',
      ]) {
        expect(ContentWebServer.resolveWithin(root, path), isNull, reason: path);
      }
    });

    test('百分号编码的 ../ 也要挡住', () {
      // 先解码再规整，不然 %2e%2e%2f 会绕过对 '../' 的检查
      expect(ContentWebServer.resolveWithin(root, '/%2e%2e%2fsecret.txt'), isNull);
      expect(ContentWebServer.resolveWithin(root, '/ab%2f..%2f..%2fsecret.txt'), isNull);
    });

    test('根目录本身不算合法目标', () {
      expect(ContentWebServer.resolveWithin(root, '/'), isNull);
    });

    test('没有根目录时一律拒掉', () {
      expect(ContentWebServer.resolveWithin('', '/index.html'), isNull);
    });
  });

  group('解压', () {
    /// 造一个 zip：[entries] 是 条目名 -> 内容。
    String makeZip(String name, Map<String, String> entries) {
      final zipPath = p.join(tmp.path, name);
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      for (final e in entries.entries) {
        final src = p.join(tmp.path, 'src', e.key.replaceAll('../', 'up_'));
        File(src).createSync(recursive: true);
        File(src).writeAsStringSync(e.value);
        encoder.addFileSync(File(src), e.key);
      }
      encoder.closeSync();
      return zipPath;
    }

    test('正常 zip 解压出来，入口是 index.html', () async {
      final d = DownloadContent(url: 'x.zip', hash: 'aabbccddee');
      final zipPath = p.join(root, d.folder, d.name);
      Directory(p.dirname(zipPath)).createSync(recursive: true);
      File(makeZip('a.zip', {
        'index.html': '<html>hi</html>',
        'js/app.js': 'console.log(1)',
      })).copySync(zipPath);

      final entry = await ContentWebServer.entryPathOf(d, root);
      expect(entry, '${d.folder}/${d.pureName}/index.html');
      expect(File(p.join(root, entry!)).existsSync(), true);
      expect(File(p.join(root, d.folder, d.pureName, 'js', 'app.js')).existsSync(), true);
    });

    test('zip 里带 ../ 的条目不能写到目录外面去', () async {
      final dest = p.join(tmp.path, 'dest');
      final zipPath = makeZip('evil.zip', {
        'index.html': 'ok',
        '../../escaped.txt': 'pwned',
      });

      expect(await ContentWebServer.unzipTo(zipPath, dest), true);
      // 正常条目照常落地
      expect(File(p.join(dest, 'index.html')).existsSync(), true);
      // 爬出去的那个被跳过，没在 dest 外面留下任何东西
      expect(File(p.join(tmp.path, 'escaped.txt')).existsSync(), false);
      expect(File(p.join(p.dirname(tmp.path), 'escaped.txt')).existsSync(), false);
    });

    test('已经解压过就直接用，不重复解', () async {
      final dest = p.join(tmp.path, 'dest2');
      final zipPath = makeZip('b.zip', {'index.html': 'v1'});
      expect(await ContentWebServer.unzipTo(zipPath, dest), true);

      // 手动改一下解压出来的内容：第二次调用不该把它覆盖回去
      File(p.join(dest, 'index.html')).writeAsStringSync('touched');
      expect(await ContentWebServer.unzipTo(zipPath, dest), true);
      expect(File(p.join(dest, 'index.html')).readAsStringSync(), 'touched');
    });

    test('zip 文件不存在返回 false', () async {
      expect(await ContentWebServer.unzipTo(p.join(tmp.path, 'nope.zip'), p.join(tmp.path, 'd')), false);
    });
  });

  group('入口解析', () {
    test('单个 html 就是它自己，不用解压', () async {
      final d = DownloadContent(url: 'page.html', hash: '1122334455');
      expect(await ContentWebServer.entryPathOf(d, root), d.path);
    });

    test('htm 一样认', () async {
      final d = DownloadContent(url: 'page.htm', hash: '1122334455');
      expect(await ContentWebServer.entryPathOf(d, root), d.path);
    });

    test('别的扩展名不是网页项', () async {
      for (var url in ['a.png', 'a.mp4', 'a.txt']) {
        final d = DownloadContent(url: url, hash: '1122334455');
        expect(await ContentWebServer.entryPathOf(d, root), isNull, reason: url);
      }
    });

    test('zip 里没有 index.html 就当用不了', () async {
      final d = DownloadContent(url: 'x.zip', hash: 'ffeeddccbb');
      final zipPath = p.join(root, d.folder, d.name);
      Directory(p.dirname(zipPath)).createSync(recursive: true);

      final encoder = ZipFileEncoder();
      final src = p.join(tmp.path, 'readme.txt');
      File(src).writeAsStringSync('nothing here');
      encoder.create(p.join(tmp.path, 'noindex.zip'));
      encoder.addFileSync(File(src), 'readme.txt');
      encoder.closeSync();
      File(p.join(tmp.path, 'noindex.zip')).copySync(zipPath);

      expect(await ContentWebServer.entryPathOf(d, root), isNull);
    });
  });
}
