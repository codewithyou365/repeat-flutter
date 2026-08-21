import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:repeat_flutter/common/zip.dart';

/// zip 里的条目名是打包方说了算的。课堂包可以是别人分享来的，所以解包前
/// 必须挡住写到目标目录外面去的条目（zip-slip）。
void main() {
  const dest = '/tmp/dest';

  test('普通条目：拼进目标目录', () {
    expect(safeZipEntryPath(dest, 'a.txt'), p.normalize('/tmp/dest/a.txt'));
    expect(safeZipEntryPath(dest, 'service/type.js'), p.normalize('/tmp/dest/service/type.js'));
  });

  test('内部的 .. 只要没跑出去就放行', () {
    expect(safeZipEntryPath(dest, 'a/../b.txt'), p.normalize('/tmp/dest/b.txt'));
  });

  test('往上跑出目标目录的一律拒绝', () {
    expect(safeZipEntryPath(dest, '../evil.txt'), isNull);
    expect(safeZipEntryPath(dest, '../../etc/passwd'), isNull);
    expect(safeZipEntryPath(dest, 'a/../../evil.txt'), isNull);
    expect(safeZipEntryPath(dest, 'a/b/../../../evil.txt'), isNull);
  });

  test('绝对路径条目拒绝', () {
    expect(safeZipEntryPath(dest, '/etc/passwd'), isNull);
  });

  test('解析成目标目录自身的拒绝', () {
    expect(safeZipEntryPath(dest, ''), isNull);
    expect(safeZipEntryPath(dest, '.'), isNull);
    expect(safeZipEntryPath(dest, 'a/..'), isNull);
  });

  test('前缀相同但不是子目录的兄弟目录拒绝', () {
    expect(safeZipEntryPath(dest, '../destevil/x.txt'), isNull);
  });
}
