import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/common/zip.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('ziptest'));
  tearDown(() => tmp.deleteSync(recursive: true));

  List<ZipArchive> payload() => [
        ZipArchive(path: 'a.txt', bytes: Uint8List.fromList('hello'.codeUnits)),
        ZipArchive(path: 'dir/b.bin', bytes: Uint8List.fromList(List.generate(5000, (i) => i % 256))),
      ];

  test('plain zip: not encrypted, round-trips', () async {
    final zf = File('${tmp.path}/plain.zip');
    await Zip.compress(payload(), zf);
    expect(await Zip.isEncrypted(zf), false);

    final out = '${tmp.path}/out_plain';
    await Zip.uncompress(zf, out);
    expect(File('$out/a.txt').readAsStringSync(), 'hello');
    expect(File('$out/dir/b.bin').lengthSync(), 5000);
  });

  test('empty password behaves as plain', () async {
    final zf = File('${tmp.path}/empty.zip');
    await Zip.compress(payload(), zf, password: '');
    expect(await Zip.isEncrypted(zf), false);
  });

  test('encrypted zip: detected, decrypts with right password', () async {
    final zf = File('${tmp.path}/enc.zip');
    await Zip.compress(payload(), zf, password: 'test123');
    expect(await Zip.isEncrypted(zf), true);

    final out = '${tmp.path}/out_enc';
    await Zip.uncompress(zf, out, password: 'test123');
    expect(File('$out/a.txt').readAsStringSync(), 'hello');
    expect(File('$out/dir/b.bin').lengthSync(), 5000);
  });

  test('wrong password throws ZipPasswordException and writes nothing', () async {
    final zf = File('${tmp.path}/enc.zip');
    await Zip.compress(payload(), zf, password: 'test123');

    final out = '${tmp.path}/out_wrong';
    await expectLater(
      Zip.uncompress(zf, out, password: 'nope'),
      throwsA(isA<ZipPasswordException>()),
    );
    expect(File('$out/a.txt').existsSync(), false);
  });

  test('stream zip: round-trips plain', () async {
    final src = File('${tmp.path}/src.bin')..writeAsBytesSync(List.generate(200000, (i) => i % 256));
    final zf = File('${tmp.path}/stream.zip');
    await Zip.compressStream([
      ZipArchive(path: 'dir/src.bin', file: src),
      ZipArchive(path: 'a.txt', bytes: Uint8List.fromList('hello'.codeUnits)),
    ], zf);

    final out = '${tmp.path}/out_stream';
    await Zip.uncompressStream(zf, out);
    expect(File('$out/dir/src.bin').lengthSync(), 200000);
    expect(File('$out/a.txt').readAsStringSync(), 'hello');
  });

  test('stream zip: round-trips encrypted, wrong password throws', () async {
    final src = File('${tmp.path}/src.bin')..writeAsStringSync('payload');
    final zf = File('${tmp.path}/stream_enc.zip');
    await Zip.compressStream([ZipArchive(path: 'src.bin', file: src)], zf, password: 'pw');
    expect(await Zip.isEncrypted(zf), true);

    final out = '${tmp.path}/out_stream_enc';
    await Zip.uncompressStream(zf, out, password: 'pw');
    expect(File('$out/src.bin').readAsStringSync(), 'payload');

    await expectLater(
      Zip.uncompressStream(zf, '${tmp.path}/out_stream_bad', password: 'nope'),
      throwsA(isA<ZipPasswordException>()),
    );
  });

  test('missing password on encrypted zip throws ZipPasswordException', () async {
    final zf = File('${tmp.path}/enc.zip');
    await Zip.compress(payload(), zf, password: 'test123');

    await expectLater(
      Zip.uncompress(zf, '${tmp.path}/out_none'),
      throwsA(isA<ZipPasswordException>()),
    );
  });
}
