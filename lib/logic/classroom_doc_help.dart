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

    // 游戏（'g'）的 'i' 是本机 Game 表的 id，对外分享时不能带出去
    if (!databaseData && classroomContent['g'] is List) {
      for (final game in classroomContent['g'] as List) {
        if (game is Map) {
          game.remove('i');
        }
      }
    }
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
