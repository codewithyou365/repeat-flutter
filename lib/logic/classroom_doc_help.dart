import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';

class ClassroomDocHelp {
  /// 把整个课堂流式写进 [sink]（文件或 HTTP response 都行）：
  ///
  ///     { ...Classroom.content... , "b":[ <book doc>, <book doc>, ... ] }
  ///
  /// 任何时候内存里只有一本书的文档，写完一本立刻 flush，
  /// 不会先在内存里拼出整份 JSON —— 课堂可能有几十上百 MB。
  ///
  /// [rootUrl] 是"文件挂在哪个地址下"。全课堂的文件都在同一个 f 目录里，
  /// 所以每本书和课堂自己共用这一个地址。给了就把 d[].u 改写成 'hh/xxxx.ext'
  /// 这种相对路径（见 [DocHelp.fixDownloadInfo]）并写上 'r'；
  /// 打 zip 时传 null，文件路径由 zip 目录结构决定。
  /// [databaseData] 为真时带上库里的 id / learnDate / progress（网络编辑用），
  /// 为假时去掉（对外分享用）。
  ///
  /// 返回每本书要打包的文件清单；出错返回 null（此时 [sink] 里是半截 JSON，调用方自己丢弃）。
  /// 课堂自己要打包的文件清单走 [classroomDownloads]。
  static Future<List<List<DownloadContent>>?> writeDoc({
    required int classroomId,
    required IOSink sink,
    required bool note,
    required bool databaseData,
    String? rootUrl,
    void Function(int done, int total)? onProgress,
  }) async {
    final classroom = await Db().db.classroomDao.getById(classroomId);
    if (classroom == null) {
      return null;
    }

    Map<String, dynamic> classroomContent;
    try {
      classroomContent = jsonDecode(classroom.content) as Map<String, dynamic>;
    } catch (e) {
      classroomContent = {};
    }

    await fillGameData(classroomContent, databaseData: databaseData);
    if (rootUrl != null) {
      DocHelp.fixDownloadInfo(classroomContent);
      classroomContent['r'] = rootUrl;
    }

    final books = await Db().db.bookDao.getAll(classroomId);

    sink.write('{');
    // 课堂自己的内容很小，逐个 key 写出去就行；'b' 是保留 key，不从这里来
    for (final entry in classroomContent.entries) {
      if (entry.key == ClassroomDocField.books) {
        continue;
      }
      sink.write('${jsonEncode(entry.key)}:${jsonEncode(entry.value)},');
    }
    sink.write('${jsonEncode(ClassroomDocField.books)}:[');

    final List<List<DownloadContent>> ret = [];
    for (var i = 0; i < books.length; i++) {
      final book = books[i];
      final bookDoc = await toBookDoc(
        book: book,
        rootUrl: rootUrl,
        note: note,
        databaseData: databaseData,
      );
      if (bookDoc == null) {
        return null;
      }
      if (i > 0) {
        sink.write(',');
      }
      sink.write(jsonEncode(bookDoc));
      await sink.flush();

      ret.add(DocHelp.getDownloads(BookContent.fromJson(bookDoc)));
      onProgress?.call(i + 1, books.length);
    }

    sink.write(']}');
    await sink.flush();
    return ret;
  }

  /// 处理课堂内容里游戏数组（'g'）跟库相关的两个 key：
  ///
  /// - 'i' 是本机 Game 表的 id，对外分享（databaseData=false）时不能带出去。
  ///   'u'/'ek'（订阅来源）和课堂的 'gs'（订阅表）反过来要带上：对方导入后照样能检查更新。
  /// - [ClassroomDocField.gameData] 是游戏自己的数据，真身在 Game 表的 data 列，
  ///   不在 [Classroom.content] 里。不管网络编辑还是对外分享，都按 'i' 从库里取出来塞进文档：
  ///   网络编辑是为了能改它，分享是为了让对方连数据一起拿走（导入时由
  ///   [ClassroomHelp] 登记游戏时写回 Game 表）。
  ///
  /// 就地改传进来的 map。
  static Future<void> fillGameData(
    Map<String, dynamic> classroomContent, {
    required bool databaseData,
  }) async {
    final games = classroomContent['g'];
    if (games is! List) {
      return;
    }
    for (final game in games) {
      if (game is! Map) {
        continue;
      }
      final id = game['i'];
      if (!databaseData) {
        game.remove('i');
      }
      if (id is! int) {
        continue;
      }
      final data = await Db().db.gameDao.getData(id);
      if (data == null || data.isEmpty) {
        // 库里没有就不覆盖：content 里可能还留着刚导入、尚未登记进 Game 表的那份数据
        continue;
      }
      game[ClassroomDocField.gameData] = decodeGameData(data);
    }
  }

  /// [fillGameData] 的反向：把 'g[].d' 摘走写回 Game 表的 data 列，
  /// 返回后 [classroomContent] 就是该存进 [Classroom.content] 的样子（不含 'd'）。
  ///
  /// 认 'i'，没有 'i' 就按游戏名找（单本编辑器里新加的游戏还没登记，两样都找不到就跳过——
  /// 那条游戏会在 [ClassroomHelp] 登记时以空 data 建出来）。
  static Future<void> takeGameData(int classroomId, Map<String, dynamic> classroomContent) async {
    final games = classroomContent['g'];
    if (games is! List) {
      return;
    }
    for (final game in games) {
      if (game is! Map || !game.containsKey(ClassroomDocField.gameData)) {
        continue;
      }
      final raw = game.remove(ClassroomDocField.gameData);
      final gameId = game['i'];
      int? id = gameId is int ? gameId : null;
      id ??= await Db().db.gameDao.getIdByName(classroomId, (game['n'] ?? '').toString());
      if (id == null) {
        continue;
      }
      await Db().db.gameDao.setData(id, encodeGameData(raw));
    }
  }

  /// 库里存的是 JSON 字符串。能解析就以原样（对象/数组/数字…）放进文档，编辑器里好改；
  /// 解析不了说明游戏自己存的就是一段裸字符串，那就原样带出去。
  static dynamic decodeGameData(String data) {
    try {
      return jsonDecode(data);
    } catch (e) {
      return data;
    }
  }

  /// [decodeGameData] 的反向。null 当成"清空"，写空串——跟游戏没写过数据时一致。
  static String encodeGameData(dynamic raw) {
    if (raw == null) {
      return '';
    }
    if (raw is String) {
      return raw;
    }
    return jsonEncode(raw);
  }

  /// 课堂自己要带走的文件（游戏 zip、提示的字体和提示服务 zip），
  /// 来自 [Classroom.content] 的 'd'。
  static Future<List<DownloadContent>> classroomDownloads(int classroomId) async {
    final classroom = await Db().db.classroomDao.getById(classroomId);
    if (classroom == null || classroom.content.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(classroom.content);
      if (decoded is! Map<String, dynamic>) return [];
      return DownloadContent.toList(decoded['d']) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// 单本书的完整文档。内容部分完全复用 [DocHelp.getDocMapFromDb]，
  /// 书名 'n' 本来就在 content 里，这里只多插一个 'i' 书本 id（仅网络编辑用）。
  static Future<Map<String, dynamic>?> toBookDoc({
    required Book book,
    required String? rootUrl,
    required bool note,
    required bool databaseData,
  }) async {
    Map<String, dynamic> bookDoc = {
      if (databaseData) ClassroomDocField.bookId: book.id,
    };
    final success = await DocHelp.getDocMapFromDb(
      bookId: book.id!,
      ret: bookDoc,
      rootUrl: rootUrl,
      note: note,
      databaseData: databaseData,
    );
    if (!success) {
      return null;
    }
    return bookDoc;
  }
}
