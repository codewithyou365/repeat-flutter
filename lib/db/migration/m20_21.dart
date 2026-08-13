import 'dart:io';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// 书本目录废弃，全课堂的文件合并到一个 `f`（files）目录里。
///
/// 老布局：`c/<课堂>/<书本>/<hh>/<xxx>.<ext>`（每本书一份）+ `c/<课堂>/g/…`（课堂级资源）
/// 新布局：`c/<课堂>/f/<hh>/<xxx>.<ext>`（全课堂一份）
///
/// 文件名本来就是 sha1 分桶的（见 DownloadContent.path），天生全局唯一，
/// 按书本再切一层目录只会让同一个媒体存好几份。
///
/// **不动库里的 content JSON**：json 里存的一直是 `<hh>/<xxx>.<ext>` 这种相对路径，
/// 变的只是"相对于谁"，所以这次迁移纯粹是搬文件。
///
/// 最后把 CrKv 里的 classroomResourceVersion 删掉，逼 registerRes 在新位置重新登记一遍。
final m20_21 = Migration(20, 21, (database) async {
  // 跟 m17_18 一样硬编码路径，不依赖 DocPath —— 那边的常量以后还会变，迁移得钉死在当时的布局上
  await migrateFilesTo21(Directory('${await sqflite.getDatabasesPath()}/c'));

  // 游戏和字体/提示的登记指纹作废，下次进课堂在新目录重新登记
  await database.rawDelete('DELETE FROM `CrKv` WHERE `k`=?', ['classroomResourceVersion']);
});

/// 把 [contentRoot] 下每个课堂的书本目录和 `g` 目录都并进该课堂的 `f`。
/// 中途崩了 floor 不会写版本号，下次重跑——每一步都是"能搬就搬、撞上就丢源"，重跑安全。
Future<void> migrateFilesTo21(Directory contentRoot) async {
  if (!await contentRoot.exists()) {
    return;
  }
  await for (final classroomDir in contentRoot.list()) {
    if (classroomDir is! Directory) continue;
    // 课堂目录是纯数字，其它的（比如整库导入的 _import_tmp）不碰
    if (int.tryParse(_baseName(classroomDir.path)) == null) continue;

    final filesDir = Directory('${classroomDir.path}/f');
    await for (final sub in classroomDir.list()) {
      if (sub is! Directory) continue;
      final subName = _baseName(sub.path);
      if (subName == 'f') continue;
      // 书本目录（纯数字）和课堂级资源目录 'g' 都并进 f；
      // 导入暂存目录 '__import' 之类的直接跳过，下面统一删
      final isBookDir = int.tryParse(subName) != null;
      if (!isBookDir && subName != 'g') continue;

      // 只搬 <hh> 两位分桶目录。书本目录里剩下的 index.json / *.zip / __root.json
      // 都是导入导出的临时产物，跟着老目录一起丢掉。
      await for (final bucket in sub.list()) {
        if (bucket is! Directory) continue;
        await moveMerge(bucket, Directory('${filesDir.path}/${_baseName(bucket.path)}'));
      }
      await _deleteQuietly(sub);
    }
    await _deleteQuietly(Directory('${classroomDir.path}/__import'));
  }
}

/// 把 [from] 整个搬到 [to]。
///
/// [to] 不存在就直接 rename 过去；已经存在就逐项搬，撞名的直接丢掉源——
/// 文件名是 sha1，撞名就说明内容一模一样，留哪一份都行。
/// rename 跨文件系统会抛异常，退化成 copy + delete。
Future<void> moveMerge(Directory from, Directory to) async {
  if (!await from.exists()) {
    return;
  }
  if (!await to.exists()) {
    try {
      await to.parent.create(recursive: true);
      await from.rename(to.path);
      return;
    } catch (e) {
      // 跨文件系统之类的，走下面逐项搬
    }
  }
  await to.create(recursive: true);
  await for (final entity in from.list()) {
    final target = '${to.path}/${_baseName(entity.path)}';
    if (entity is Directory) {
      await moveMerge(entity, Directory(target));
    } else if (entity is File) {
      if (await File(target).exists()) {
        await _deleteQuietly(entity);
        continue;
      }
      try {
        await entity.rename(target);
      } catch (e) {
        await entity.copy(target);
        await _deleteQuietly(entity);
      }
    }
  }
  await _deleteQuietly(from);
}

String _baseName(String path) {
  final segments = path.split(Platform.pathSeparator).where((e) => e.isNotEmpty);
  return segments.isEmpty ? '' : segments.last;
}

Future<void> _deleteQuietly(FileSystemEntity entity) async {
  try {
    if (await entity.exists()) {
      await entity.delete(recursive: true);
    }
  } catch (e) {
    // 删不掉就留着，不值得让整个迁移失败
  }
}
