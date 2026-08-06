import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/json_splitter.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/import_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';
import 'package:repeat_flutter/logic/model/zip_index_doc.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 导入一整个课堂（zip 或远程）。
///
/// **总是新建课堂**：重名自动加后缀，绝不合并进已有课堂，也就绝不会碰到已有的学习进度。
///
/// 整份 index.json 可能几十上百 MB，所以先用 [JsonSplitter] 按书切成一堆小文件，
/// 再一本一本交给现有的 [ImportHelp.import]，内存里始终只有一本书。
class ClassroomImportHelp {
  /// 导入过程中的暂存目录，放在新课堂目录下，成功/失败都会删掉
  static const String stagingDir = '__import';

  static Future<ClassroomImportResult?> fromZip({
    required String zipPath,
    required String classroomName,
    String? password,
    void Function(int done, int total)? onProgress,
  }) async {
    return _run(
      classroomName: classroomName,
      onProgress: onProgress,
      prepare: (classroomId, stagingPath) async {
        await Zip.uncompressStream(File(zipPath), stagingPath, password: password);
        final zipRoot = await ZipRootDoc.fromPath(stagingPath.joinPath(DocPath.zipRootFile));
        return _Source(
          indexFile: File(stagingPath.joinPath(DocPath.getIndexFileName())),
          url: zipRoot?.url ?? '',
          // zip 里媒体按书本在 'b' 数组里的下标分目录，直接搬过去就行
          mediaDirOf: (index) => stagingPath.joinPath('$index'),
        );
      },
    );
  }

  static Future<ClassroomImportResult?> fromUrl({
    required String url,
    required String classroomName,
    String credentials = '',
    void Function(int done, int total)? onProgress,
    DownloadProgressCallback? downloadProgress,
  }) async {
    return _run(
      classroomName: classroomName,
      onProgress: onProgress,
      prepare: (classroomId, stagingPath) async {
        final indexPath = DocPath.getClassroomRelativePath(classroomId).joinPath(stagingDir).joinPath(DocPath.getIndexFileName());
        final result = await DownloadDoc.start(
          url,
          indexPath,
          credentials: credentials,
          progressCallback: downloadProgress,
          skipSsl: true,
        );
        if (result != DownloadDocResult.success) {
          return null;
        }
        return _Source(
          indexFile: File(stagingPath.joinPath(DocPath.getIndexFileName())),
          url: url,
          credentials: credentials,
          downloadProgress: downloadProgress,
        );
      },
    );
  }

  static Future<ClassroomImportResult?> _run({
    required String classroomName,
    required Future<_Source?> Function(int classroomId, String stagingPath) prepare,
    void Function(int done, int total)? onProgress,
  }) async {
    final classroom = await Db().db.classroomDao.addWithUniqueName(classroomName);
    final rootPath = await DocPath.getContentPath();
    final classroomPath = rootPath.joinPath(DocPath.getClassroomRelativePath(classroom.id));
    final stagingPath = classroomPath.joinPath(stagingDir);

    try {
      await Folder.delete(stagingPath);
      await Folder.ensureExists(stagingPath);

      final source = await prepare(classroom.id, stagingPath);
      if (source == null) {
        throw Exception(I18nKey.labelDataAnomaly.trArgs(['index.json']));
      }

      // 按书切开：head 是课堂自己的内容，每本书一个文件
      final splitter = JsonSplitter(
        outDir: stagingPath.joinPath('books'),
        arrayKey: ClassroomDocField.books,
      );
      if (!await splitter.split(source.indexFile)) {
        throw Exception(I18nKey.labelDataAnomalyWithArg.trArgs(['classroom index.json']));
      }
      await Db().db.classroomDao.updateContent(classroom.id, jsonEncode(splitter.head));

      final total = splitter.elementPaths.length;
      for (var i = 0; i < total; i++) {
        await _importOneBook(
          classroomId: classroom.id,
          index: i,
          bookDocPath: splitter.elementPaths[i],
          rootPath: rootPath,
          source: source,
        );
        onProgress?.call(i + 1, total);
      }

      await Folder.delete(stagingPath);
      return ClassroomImportResult(classroom: classroom, bookCount: total);
    } catch (e) {
      // 不留半个课堂：连课堂带目录一起回滚
      await Db().db.classroomDao.deleteAll(classroom.id);
      await Folder.delete(classroomPath);
      Snackbar.show(I18nKey.labelClassroomImportFail.trArgs([e.toString()]));
      return null;
    }
  }

  static Future<void> _importOneBook({
    required int classroomId,
    required int index,
    required String bookDocPath,
    required String rootPath,
    required _Source source,
  }) async {
    final bookDoc = jsonDecode(await File(bookDocPath).readAsString()) as Map<String, dynamic>;
    // 书名就在内容的 'n' 里；老的单本文档没有名字，按顺序编一个
    var name = bookDoc[bookNameKey] as String? ?? '';
    if (name.isEmpty) {
      name = 'book${index + 1}';
      bookDoc[bookNameKey] = name;
      await File(bookDocPath).writeAsString(jsonEncode(bookDoc));
    }

    final book = await Db().db.bookDao.addTo(classroomId, name);
    final bookPath = rootPath.joinPath(DocPath.getRelativePathOf(classroomId, book.id!));
    await Folder.ensureExists(bookPath);

    // 书本文档挪到它自己的目录，ImportHelp 只认这个位置
    await File(bookDocPath).rename(bookPath.joinPath(DocPath.getIndexFileName()));

    final mediaDir = source.mediaDirOf?.call(index);
    if (mediaDir != null) {
      await _moveInto(mediaDir, bookPath);
    } else {
      await _downloadMedia(bookDoc: bookDoc, bookPath: DocPath.getRelativePathOf(classroomId, book.id!), source: source);
    }

    // desc / sort / enable / url 不在文档里，走 addTo 给的默认值，
    // ImportHelp 会把 url 设成来源地址、书本置为启用。
    if (!await ImportHelp.import(book.id!, source.url)) {
      throw Exception(I18nKey.labelDataAnomalyWithArg.trArgs(['book $name']));
    }
  }

  static Future<void> _downloadMedia({
    required Map<String, dynamic> bookDoc,
    required String bookPath,
    required _Source source,
  }) async {
    final content = BookContent.fromJson(bookDoc);
    final rootUrl = source.url.substring(0, source.url.lastIndexOf("/"));
    final downloads = DocHelp.getDownloads(content, rootUrl: rootUrl);
    for (final d in downloads) {
      final result = await DownloadDoc.start(
        d.url,
        bookPath.joinPath(d.path),
        credentials: source.credentials,
        hash: d.hash,
        progressCallback: source.downloadProgress,
        skipSsl: true,
      );
      if (result != DownloadDocResult.success) {
        throw Exception(I18nKey.labelDataAnomalyWithArg.trArgs([d.url]));
      }
    }
  }

  /// 把 [from] 目录下的东西整个搬到 [to]，搬完删掉 [from]
  static Future<void> _moveInto(String from, String to) async {
    final dir = Directory(from);
    if (!await dir.exists()) {
      return;
    }
    await for (final entity in dir.list()) {
      final target = to.joinPath(entity.uri.pathSegments.where((e) => e.isNotEmpty).last);
      if (entity is Directory) {
        await Folder.delete(target);
        await entity.rename(target);
      } else if (entity is File) {
        await entity.rename(target);
      }
    }
    await Folder.delete(from);
  }
}

class ClassroomImportResult {
  final Classroom classroom;
  final int bookCount;

  ClassroomImportResult({required this.classroom, required this.bookCount});
}

/// 课堂内容从哪来：zip 是本地目录，远程是一串 URL
class _Source {
  final File indexFile;
  final String url;
  final String credentials;
  final DownloadProgressCallback? downloadProgress;

  /// zip 导入时给出第 index 本书的媒体目录；远程导入为 null（改成逐个下载）
  final String Function(int index)? mediaDirOf;

  _Source({
    required this.indexFile,
    required this.url,
    this.credentials = '',
    this.downloadProgress,
    this.mediaDirOf,
  });
}
