import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/tip.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/classroom_doc_help.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class ContentEntry {
  int? id;
  String hash;
  String name;

  /// 'k'：用户填的运行期 key，原样喂给游戏（见 game_server/controller/game_key.dart）。
  /// **跟 manifest 里的入口标识没有任何关系**，那个是 [entryKey]。
  String key;
  String service;
  String? mapKey;

  /// 'u'：这条游戏来自哪个订阅（manifest 的 URL）。空 = 本地导入的，不参与更新。
  /// 只有 'g' 的条目有，提示/字体那些用不到。
  String subUrl;

  /// 'ek'：manifest 里那个入口的 key。跟 [subUrl] 一起做升级时的匹配主键。
  String entryKey;

  ContentEntry({
    this.id,
    required this.hash,
    required this.name,
    required this.key,
    required this.service,
    this.mapKey,
    this.subUrl = '',
    this.entryKey = '',
  });

  factory ContentEntry.fromJson(Map<String, dynamic> json, {String? mapKey}) {
    return ContentEntry(
      id: json['i'] as int?,
      hash: json['h'] ?? '',
      name: json['n'] ?? '',
      key: json['k'] ?? '',
      service: json['s'] ?? '',
      mapKey: mapKey,
      // 'u' 在别的地方（DownloadContent）是另一个含义，这里宽松点转，别为了个不用的字段崩掉。
      subUrl: (json['u'] ?? '').toString(),
      entryKey: (json['ek'] ?? '').toString(),
    );
  }
}

class ClassroomHelp {
  static Map<int, String> savedVersionSigCacheMap = {};

  /// 课堂级提示（Classroom.content 的 't'）在 Tip 表里的 bookId。
  /// 提示的名字/字体/服务配置是整个课堂共用的，不挂在某一本书下面；
  /// 唯一索引 ('bookId','t') 照样成立——课堂级只有一套 't'/'t1'/…。
  /// 'q'/'a'/'n' 的提示服务仍然是每本书各一份，用真实 bookId。
  static const int classroomBookId = 0;

  /// 课堂资源的版本指纹：课堂自己的内容版本 + 每本书的内容版本。
  /// 游戏和提示挂在课堂上、'q'/'a'/'n' 的字体挂在书上，任何一边变了都要重新登记。
  static Future<String> _versionSig(int classroomId, List<Book> books) async {
    final classroom = await Db().db.classroomDao.getById(classroomId);
    books.sort((a, b) => a.id!.compareTo(b.id!));
    final bookPart = books.map((e) => '${e.id}:${e.contentVersion}').join(',');
    return '${classroom?.contentVersion ?? -1}|$bookPart';
  }

  static Future<void> registerRes() async {
    try {
      final classroomId = Classroom.curr;
      var books = await Db().db.bookDao.getAll(classroomId);
      String savedVersionSigCache = savedVersionSigCacheMap[classroomId] ?? '';
      var currentVersionSig = await _versionSig(classroomId, books);

      if (currentVersionSig == savedVersionSigCache) return;

      final rootPath = await DocPath.getContentPath();
      final Set<String> currentTipKeys = {};

      // 字体是注册进本进程的，跟库里存的版本无关，每次进来都要过一遍
      for (var book in books) {
        if (book.content.isEmpty) continue;

        Map<String, dynamic> bookMap = jsonDecode(book.content);
        List<DownloadContent> downloads = DownloadContent.toList(bookMap['d']) ?? [];

        for (var prefix in bookFieldRefs) {
          await _registerFont(bookMap, prefix, downloads, DocPath.getFilesRelativePath(), rootPath);
        }
      }
      // 提示的字体在课堂那一层；字体文件跟书本的字体一样，都在课堂的文件目录里
      await _registerClassroomFonts(classroomId, rootPath);

      savedVersionSigCacheMap[classroomId] = currentVersionSig;
      final savedVersionSig = await Db().db.crKvDao.getStr(classroomId, CrK.classroomResourceVersion);
      if (currentVersionSig == savedVersionSig) return;

      await _registerGames(classroomId);
      await _registerTips(classroomId, currentTipKeys);

      for (var book in books) {
        if (book.content.isEmpty) continue;

        Map<String, dynamic> bookMap = jsonDecode(book.content);
        List<DownloadContent> downloads = DownloadContent.toList(bookMap['d']) ?? [];

        // 'q'/'a'/'n' 的提示服务配置放在各字段块自己身上，Tip.t 存的就是这个字段引用串。
        // 提示（'t'/'t1'/…）不在这里，见 [_registerTips]。
        for (final fieldRef in bookFieldRefs) {
          final entryMap = VerseField.of(bookMap, fieldRef);
          if (entryMap == null) continue;
          final tip = ContentEntry.fromJson(entryMap, mapKey: fieldRef);
          final ok = await _ensureContentReady(tip, downloads, DocPath.getFilesRelativePath());
          if (!ok) continue;

          final id = await _upsertTip(
            entry: tip,
            classroomId: classroomId,
            bookId: book.id!,
            fieldRef: fieldRef,
          );
          if (id != null) {
            entryMap['i'] = id;
          }
          currentTipKeys.add('${book.id}-$fieldRef');
        }
        Db().db.bookDao.updateBookContent(book.id!, jsonEncode(bookMap));
      }
      final dbTips = await Db().db.tipDao.getByClassroomId(Classroom.curr);
      for (var dbTip in dbTips) {
        final key = '${dbTip.bookId}-${dbTip.t}';
        if (!currentTipKeys.contains(key)) {
          await Db().db.tipDao.deleteByType(dbTip.bookId, dbTip.t);
        }
      }
      // 上面回写过 'i'，版本号已经变了，重新算一遍再记下来
      books = await Db().db.bookDao.getAll(classroomId);
      currentVersionSig = await _versionSig(classroomId, books);
      Db().db.crKvDao.insertOrReplace(
        CrKv(
          classroomId,
          CrK.classroomResourceVersion,
          currentVersionSig,
        ),
      );
      savedVersionSigCacheMap[classroomId] = currentVersionSig;
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
    }
  }

  /// 游戏是整个课堂全局的：宣告在 [Classroom.content] 的 'g' 里，zip 也从课堂自己的
  /// 'd' 里找，落在 [DocPath.getFilesRelativePathOf] 下，不再挂到某一本书上。
  static Future<void> _registerGames(int classroomId) async {
    final classroom = await Db().db.classroomDao.getById(classroomId);
    if (classroom == null || classroom.content.isEmpty) return;

    Map<String, dynamic> classroomMap;
    try {
      final decoded = jsonDecode(classroom.content);
      if (decoded is! Map<String, dynamic>) return;
      classroomMap = decoded;
    } catch (e) {
      return;
    }

    final downloads = DownloadContent.toList(classroomMap['d']) ?? [];
    final gameData = classroomMap['g'] is List ? classroomMap['g'] as List<dynamic> : <dynamic>[];
    final resPath = DocPath.getFilesRelativePathOf(classroomId);
    final Set<String> currentGameNames = {};
    var contentChanged = false;

    final games = _entriesFromList(gameData);
    for (var i = 0; i < games.length; i++) {
      final game = games[i];
      final ok = await _ensureContentReady(game, downloads, resPath);
      if (!ok) continue;

      // 分享文档会把游戏数据（'d'）一起带过来（见 [ClassroomDocHelp.fillGameData]）。
      // 数据的真身是 Game.data，content 里只放宣告，所以写进库之后就把这个 key 摘掉。
      final rawGame = gameData[i];
      String? importedData;
      if (rawGame is Map && rawGame.containsKey(ClassroomDocField.gameData)) {
        importedData = ClassroomDocHelp.encodeGameData(rawGame.remove(ClassroomDocField.gameData));
        contentChanged = true;
      }

      Game? gameEntity;
      if (game.id != null) {
        gameEntity = await Db().db.gameDao.getById(game.id!);
        if (gameEntity != null && gameEntity.classroomId != classroomId) {
          gameEntity = null;
        }
      }
      if (gameEntity == null) {
        await Db().db.gameDao.insertOrReplace(
          Game(
            classroomId: classroomId,
            k: game.key,
            name: game.name,
            hash: game.hash,
            data: importedData ?? '',
            service: game.service,
            createTime: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        gameData[i]['i'] = await Db().db.gameDao.getIdByName(classroomId, game.name);
        contentChanged = true;
      } else {
        gameEntity.k = game.key;
        gameEntity.name = game.name;
        gameEntity.hash = game.hash;
        gameEntity.service = game.service;
        if (importedData != null) {
          gameEntity.data = importedData;
        }
        await Db().db.gameDao.updateOrReplace(gameEntity);
      }
      currentGameNames.add(game.name);
    }

    final dbGames = await Db().db.gameDao.getByClassroomId(classroomId);
    for (var dbGame in dbGames) {
      if (!currentGameNames.contains(dbGame.name)) {
        // 游戏没了，它那张 kv 表（熟词库之类）也一起清掉：gameId 是自增主键，
        // 留着的话下一个游戏拿到同一个 id 就会读到上一个游戏的数据
        if (dbGame.id != null) {
          await Db().db.gameKvDao.deleteByGameId(dbGame.id!);
        }
        await Db().db.gameDao.deleteByName(classroomId, dbGame.name);
      }
    }

    if (contentChanged) {
      await Db().db.classroomDao.updateContent(classroomId, jsonEncode(classroomMap));
    }
  }

  static List<ContentEntry> _entriesFromList(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data.map((e) => ContentEntry.fromJson(e)).toList();
  }

  /// book 那一层有哪些字段块：只有 'q'/'a'/'n'。
  /// 提示（'t'/'t1'/…）的字体和提示服务配置在课堂那一层，见 [_registerTips]。
  static const List<String> bookFieldRefs = ['q', 'a', 'n'];

  /// 课堂 't' 数组展开成的字段引用串：'t'、't1'、't2'…
  static List<String> classroomTipRefs(Map<String, dynamic> classroomMap) {
    final tipLength = VerseField.tipLength(classroomMap);
    return [
      for (var i = 0; i < (tipLength == 0 ? 1 : tipLength); i++) VerseField.ref('t', i),
    ];
  }

  static Map<String, dynamic>? _decodeMap(String? content) {
    if (content == null || content.isEmpty) return null;
    try {
      final decoded = jsonDecode(content);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      return null;
    }
  }

  /// 把 [fieldRef] 这一块声明的字体注册进本进程。字体文件在 [relativeFolder] 下。
  static Future<void> _registerFont(
    Map<String, dynamic> content,
    String fieldRef,
    List<DownloadContent> downloads,
    String relativeFolder,
    String rootPath,
  ) async {
    final alias = VerseField.getStr(content, fieldRef, VerseField.fontAlias);
    final hash = VerseField.getStr(content, fieldRef, VerseField.fontHash);
    if (alias == null || hash == null) return;

    final download = downloads.firstWhereOrNull((e) => e.hash == hash);
    if (download == null) return;

    final localFolder = rootPath.joinPath(relativeFolder.joinPath(download.folder));
    await registerCustomFont(alias, localFolder.joinPath(download.name));
  }

  /// 提示的字体：声明在 [Classroom.content] 的 't' 里，文件在课堂的文件目录下。
  static Future<void> _registerClassroomFonts(int classroomId, String rootPath) async {
    final classroom = await Db().db.classroomDao.getById(classroomId);
    final classroomMap = _decodeMap(classroom?.content);
    if (classroomMap == null) return;

    final downloads = DownloadContent.toList(classroomMap['d']) ?? [];
    final resPath = DocPath.getFilesRelativePathOf(classroomId);
    for (final fieldRef in classroomTipRefs(classroomMap)) {
      await _registerFont(classroomMap, fieldRef, downloads, resPath, rootPath);
    }
  }

  /// 提示的服务配置（'h'/'k'/'s'/'i'）也在课堂那一层，zip 从课堂自己的 'd' 里找、
  /// 落在 [DocPath.getFilesRelativePathOf] 下（跟游戏一样）。
  /// Tip 行的 bookId 一律写 [classroomBookId]：整个课堂共用一套，不挂在某一本书下面。
  static Future<void> _registerTips(int classroomId, Set<String> currentTipKeys) async {
    final classroom = await Db().db.classroomDao.getById(classroomId);
    final classroomMap = _decodeMap(classroom?.content);
    if (classroomMap == null) return;

    final downloads = DownloadContent.toList(classroomMap['d']) ?? [];
    final resPath = DocPath.getFilesRelativePathOf(classroomId);
    var contentChanged = false;

    for (final fieldRef in classroomTipRefs(classroomMap)) {
      final entryMap = VerseField.of(classroomMap, fieldRef);
      if (entryMap == null) continue;
      final entry = ContentEntry.fromJson(entryMap, mapKey: fieldRef);
      final ok = await _ensureContentReady(entry, downloads, resPath);
      if (!ok) continue;

      final id = await _upsertTip(
        entry: entry,
        classroomId: classroomId,
        bookId: classroomBookId,
        fieldRef: fieldRef,
      );
      if (id != null) {
        entryMap['i'] = id;
        contentChanged = true;
      }
      currentTipKeys.add('$classroomBookId-$fieldRef');
    }

    if (contentChanged) {
      await Db().db.classroomDao.updateContent(classroomId, jsonEncode(classroomMap));
    }
  }

  /// 建/更新一行 Tip。新建时返回新行的 id（调用方回写进 'i'），更新已有行时返回 null。
  static Future<int?> _upsertTip({
    required ContentEntry entry,
    required int classroomId,
    required int bookId,
    required String fieldRef,
  }) async {
    Tip? tipEntity;
    if (entry.id != null) {
      tipEntity = await Db().db.tipDao.getById(entry.id!);
      if (tipEntity == null || tipEntity.bookId != bookId) {
        tipEntity = null;
      }
    }
    if (tipEntity == null) {
      await Db().db.tipDao.insertOrReplace(
        Tip(
          classroomId: classroomId,
          bookId: bookId,
          t: fieldRef,
          k: entry.key,
          hash: entry.hash,
          service: entry.service,
          createTime: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return await Db().db.tipDao.getIdByType(bookId, fieldRef);
    }
    tipEntity.t = fieldRef;
    tipEntity.k = entry.key;
    tipEntity.hash = entry.hash;
    tipEntity.service = entry.service;
    await Db().db.tipDao.updateOrReplace(tipEntity);
    return null;
  }

  // Re-unzip the content of a tip if its folder has been removed after the
  // last registerRes(), e.g. by the "remove useless files" action of the editor.
  static Future<bool> ensureContentReadyByHash(int bookId, String hash) async {
    if (hash.isEmpty) {
      return false;
    }
    final book = await Db().db.bookDao.getById(bookId);
    if (book == null || book.content.isEmpty) {
      return false;
    }
    final Map<String, dynamic> bookMap = jsonDecode(book.content);
    final downloads = DownloadContent.toList(bookMap['d']) ?? [];
    final entry = ContentEntry(hash: hash, name: '', key: '', service: '');
    return await _ensureContentReady(entry, downloads, DocPath.getFilesRelativePath());
  }

  /// 同上，但找的是课堂自己的 'd'（游戏 zip 在这里）。
  static Future<bool> ensureClassroomContentReadyByHash(int classroomId, String hash) async {
    if (hash.isEmpty) {
      return false;
    }
    final classroom = await Db().db.classroomDao.getById(classroomId);
    if (classroom == null || classroom.content.isEmpty) {
      return false;
    }
    Map<String, dynamic> classroomMap;
    try {
      final decoded = jsonDecode(classroom.content);
      if (decoded is! Map<String, dynamic>) return false;
      classroomMap = decoded;
    } catch (e) {
      return false;
    }
    final downloads = DownloadContent.toList(classroomMap['d']) ?? [];
    final entry = ContentEntry(hash: hash, name: '', key: '', service: '');
    return await _ensureContentReady(entry, downloads, DocPath.getFilesRelativePathOf(classroomId));
  }

  /// [relativeFolder] 是这份资源所在的相对目录。书本级和课堂级现在都是课堂的文件目录，
  /// 参数留着是因为课堂可能不是 [Classroom.curr]（见 [DocPath.getFilesRelativePathOf]）。
  static Future<bool> _ensureContentReady(
    ContentEntry entry,
    List<DownloadContent> downloads,
    String relativeFolder,
  ) async {
    if (entry.hash.isEmpty) {
      return false;
    }
    final download = downloads.firstWhereOrNull((e) => e.hash == entry.hash);
    if (download == null) {
      return false;
    }
    final rootPath = await DocPath.getContentPath();
    final localFolder = rootPath.joinPath(relativeFolder);
    final zipFilePath = localFolder.joinPath(download.folder).joinPath(download.name);
    final destinationDir = localFolder.joinPath(download.folder).joinPath(download.pureName);
    return await unzipGame(zipFilePath, destinationDir);
  }

  static Future<bool> unzipGame(String zipFilePath, String destPath) async {
    try {
      final zipFile = File(zipFilePath);
      if (!await zipFile.exists()) return false;

      await Folder.deleteIfEmpty(destPath);
      final destinationDir = Directory(destPath);
      if (await destinationDir.exists()) return true;

      final inputStream = InputFileStream(zipFilePath);
      final archive = ZipDecoder().decodeStream(inputStream);

      for (final file in archive) {
        if (file.isFile) {
          final outputStream = OutputFileStream('$destPath/${file.name}');
          file.writeContent(outputStream);
          await outputStream.close();
        }
      }
      return true;
    } catch (e) {
      debugPrint("Unzip failed: $e");
      return false;
    }
  }

  static Future<bool> registerCustomFont(String alias, String filePath) async {
    try {
      final File fontFile = File(filePath);
      if (!await fontFile.exists()) return false;

      final Uint8List fontBytes = await fontFile.readAsBytes();

      final fontLoader = FontLoader(alias);

      fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));

      await fontLoader.load();
    } catch (e) {
      return false;
    }
    return true;
  }
}
