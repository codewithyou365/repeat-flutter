import 'dart:convert' as convert;
import 'dart:io';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// 提示（'t'）的名字、字体和提示服务配置从"每本书各存一份"改成"整个课堂一份"。
///
/// - 宣告：每本书 content 的 't' 数组搬进课堂 content 的 't'，逐下标合并——
///   下标就是提示的身份（课堂的第 i 条名字配的就是每一节第 i 条正文），
///   所以只按下标对齐，缺哪个 key 补哪个，先到先得（书按 id 升序，低 id 的书赢）。
///   'i'（Tip 行 id）不搬，下次 ClassroomHelp.registerRes 会重新登记回来。
/// - 文件：搬走的字体 ttf / 提示服务 zip 从书本的 'd' 挪进课堂的 'd'（按 hash 去重），
///   文件从 c/<课堂>/<书本>/<hh>/<xxx>.<ext> 搬到 c/<课堂>/g/<hh>/<xxx>.<ext>，
///   老的解压目录直接删掉，下次 registerRes 会在新位置重新解压。跟 m17_18 搬游戏一样。
/// - book 的 't' 整个删掉（verse 的 't' 一个字节都不动，那里放的是正文/媒体/区间）。
/// - 表：Tip 结构不变，但提示那几行的归属变了（课堂级用 bookId=0，
///   见 ClassroomHelp.classroomBookId），所以把老的提示行删掉重新登记。
///   'q'/'a'/'n' 的行还是书本级的，原样留着。
///
/// 最后把 CrKv 里的 classroomResourceVersion 删掉，逼 registerRes 重新登记一遍。
final m18_19 = Migration(18, 19, (database) async {
  final contentRoot = '${await sqflite.getDatabasesPath()}/c';

  /// 搬到课堂那一层的 key：名字、字体、提示服务配置。
  const movedKeys = ['n', 'fontSize', 'fontAlias', 'fontHash', 'h', 'k', 's'];

  /// 引用了文件的 key：它们的值就是 'd' 里某条 DownloadContent 的 hash。
  const hashKeys = ['fontHash', 'h'];

  Map<String, dynamic> decodeMap(Object? raw) {
    final text = (raw as String?) ?? '';
    if (text.isEmpty) return <String, dynamic>{};
    try {
      final decoded = convert.jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  /// 't' 可能是老格式的单个 map（那时候提示只有一条），先归一成数组。
  List<dynamic> tipListOf(Map<String, dynamic> map) {
    final raw = map['t'];
    if (raw is List) return raw;
    if (raw is Map) return [raw];
    return <dynamic>[];
  }

  // DownloadContent 的路径规则：文件夹取 hash 前两位，文件名是剩下的 hash + 扩展名
  String folderOf(String hash) => hash.substring(0, 2);
  String pureNameOf(String hash) => hash.substring(2);
  String fileNameOf(String hash, String url) => '${pureNameOf(hash)}.${url.split('.').last}';

  final classrooms = await database.rawQuery('SELECT `id`,`content` FROM `Classroom`');
  for (final classroom in classrooms) {
    final classroomId = classroom['id'] as int;
    final classroomMap = decodeMap(classroom['content']);
    final classroomTips = tipListOf(classroomMap).toList();
    final classroomDownloads = (classroomMap['d'] as List?)?.toList() ?? <dynamic>[];
    final classroomHashes = classroomDownloads.whereType<Map>().map((e) => e['h'] as String?).whereType<String>().toSet();
    var classroomChanged = false;

    final books = await database.rawQuery(
      'SELECT `id`,`content` FROM `Book` WHERE `classroomId`=? ORDER BY `id`',
      [classroomId],
    );
    for (final book in books) {
      final bookId = book['id'] as int;
      final bookMap = decodeMap(book['content']);
      final bookTips = tipListOf(bookMap);
      if (bookTips.isEmpty) {
        continue;
      }
      final bookDownloads = (bookMap['d'] as List?) ?? <dynamic>[];

      for (var i = 0; i < bookTips.length; i++) {
        final bookTip = bookTips[i];
        if (bookTip is! Map) continue;

        while (classroomTips.length <= i) {
          classroomTips.add(<String, dynamic>{});
        }
        var classroomTip = classroomTips[i];
        if (classroomTip is! Map) {
          classroomTip = <String, dynamic>{};
          classroomTips[i] = classroomTip;
        }

        for (final key in movedKeys) {
          final value = bookTip[key];
          if (value == null || classroomTip[key] != null) continue;
          classroomTip[key] = value;

          if (!hashKeys.contains(key)) continue;
          final hash = value as String?;
          if (hash == null || hash.length < 3) continue;

          final download = bookDownloads.whereType<Map>().firstWhere(
                (e) => e['h'] == hash,
                orElse: () => <String, dynamic>{},
              );
          if (download.isEmpty) continue;

          if (classroomHashes.add(hash)) {
            classroomDownloads.add(download);
          }
          bookDownloads.removeWhere((e) => e is Map && e['h'] == hash);

          // 文件搬家：ttf/zip 挪过去，老的解压目录删掉
          final url = (download['u'] as String?) ?? '.zip';
          final folder = folderOf(hash);
          final fileName = fileNameOf(hash, url);
          final from = File('$contentRoot/$classroomId/$bookId/$folder/$fileName');
          if (await from.exists()) {
            final toDir = Directory('$contentRoot/$classroomId/g/$folder');
            if (!await toDir.exists()) {
              await toDir.create(recursive: true);
            }
            final to = '${toDir.path}/$fileName';
            try {
              await from.rename(to);
            } catch (e) {
              await from.copy(to);
              await from.delete();
            }
          }
          final unzipped = Directory('$contentRoot/$classroomId/$bookId/$folder/${pureNameOf(hash)}');
          if (await unzipped.exists()) {
            await unzipped.delete(recursive: true);
          }
        }
      }

      bookMap.remove('t');
      bookMap['d'] = bookDownloads;
      await database.rawUpdate(
        'UPDATE `Book` SET `content`=?,`contentVersion`=`contentVersion`+1 WHERE `id`=?',
        [convert.jsonEncode(bookMap), bookId],
      );
      classroomChanged = true;
    }

    if (classroomChanged) {
      classroomMap['t'] = classroomTips;
      classroomMap['d'] = classroomDownloads;
      await database.rawUpdate(
        'UPDATE `Classroom` SET `content`=?,`contentVersion`=`contentVersion`+1 WHERE `id`=?',
        [convert.jsonEncode(classroomMap), classroomId],
      );
    }
  }

  // 提示的 Tip 行归属变了（现在挂在课堂上，bookId=0），删掉重新登记；
  // 't' 是第 1 条，'t1'..'t7' 是后面几条（VerseField.maxTip = 8）。
  await database.rawDelete("DELETE FROM `Tip` WHERE `t`='t' OR `t` GLOB 't[0-9]'");

  // 字体和提示的登记指纹作废，下次进课堂重新登记
  await database.rawDelete('DELETE FROM `CrKv` WHERE `k`=?', ['classroomResourceVersion']);
});
