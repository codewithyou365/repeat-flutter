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
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class ContentEntry {
  int? id;
  String hash;
  String name;
  String key;
  String service;
  String? mapKey;

  ContentEntry({
    this.id,
    required this.hash,
    required this.name,
    required this.key,
    required this.service,
    this.mapKey,
  });

  factory ContentEntry.fromJson(Map<String, dynamic> json, {String? mapKey}) {
    return ContentEntry(
      id: json['i'] as int?,
      hash: json['h'] ?? '',
      name: json['n'] ?? '',
      key: json['k'] ?? '',
      service: json['s'] ?? '',
      mapKey: mapKey,
    );
  }
}

class ClassroomHelp {
  static Map<int, String> savedVersionSigCacheMap = {};

  /// 课堂资源的版本指纹：课堂自己的内容版本 + 每本书的内容版本。
  /// 游戏挂在课堂上、字体和提示挂在书上，任何一边变了都要重新登记。
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

        for (var prefix in _fieldRefs(bookMap)) {
          String? alias = VerseField.getStr(bookMap, prefix, VerseField.fontAlias);
          String? hash = VerseField.getStr(bookMap, prefix, VerseField.fontHash);

          if (alias != null && hash != null) {
            final download = downloads.firstWhereOrNull((e) => e.hash == hash);
            if (download != null) {
              final localFolder = rootPath.joinPath(DocPath.getRelativePath(book.id!).joinPath(download.folder));
              final filePath = localFolder.joinPath(download.name);

              await registerCustomFont(alias, filePath);
            }
          }
        }
      }

      savedVersionSigCacheMap[classroomId] = currentVersionSig;
      final savedVersionSig = await Db().db.crKvDao.getStr(classroomId, CrK.classroomResourceVersion);
      if (currentVersionSig == savedVersionSig) return;

      await _registerGames(classroomId);

      for (var book in books) {
        if (book.content.isEmpty) continue;

        Map<String, dynamic> bookMap = jsonDecode(book.content);
        List<DownloadContent> downloads = DownloadContent.toList(bookMap['d']) ?? [];

        // 提示服务配置就放在各字段块自己身上（'q'/'a'/'n' 各一个，提示是 't'/'t1'/'t2'…），
        // Tip.t 存的就是这个字段引用串。
        for (final fieldRef in _fieldRefs(bookMap)) {
          final entryMap = VerseField.of(bookMap, fieldRef);
          if (entryMap == null) continue;
          final tip = ContentEntry.fromJson(entryMap, mapKey: fieldRef);
          final ok = await _ensureContentReady(tip, downloads, DocPath.getRelativePath(book.id!));
          if (!ok) continue;

          Tip? tipEntity;
          if (tip.id != null) {
            tipEntity = await Db().db.tipDao.getById(tip.id!);
            if (tipEntity == null || tipEntity.bookId != book.id!) {
              tipEntity = null;
            }
          }
          if (tipEntity == null) {
            await Db().db.tipDao.insertOrReplace(
              Tip(
                classroomId: Classroom.curr,
                bookId: book.id!,
                t: fieldRef,
                k: tip.key,
                hash: tip.hash,
                service: tip.service,
                createTime: DateTime.now().millisecondsSinceEpoch,
              ),
            );
            entryMap['i'] = await Db().db.tipDao.getIdByType(book.id!, fieldRef);
          } else {
            tipEntity.t = fieldRef;
            tipEntity.k = tip.key;
            tipEntity.hash = tip.hash;
            tipEntity.service = tip.service;
            await Db().db.tipDao.updateOrReplace(tipEntity);
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
  /// 'd' 里找，落在 [DocPath.getClassroomResRelativePath] 下，不再挂到某一本书上。
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
    final resPath = DocPath.getClassroomResRelativePath(classroomId);
    final Set<String> currentGameNames = {};
    var contentChanged = false;

    final games = _entriesFromList(gameData);
    for (var i = 0; i < games.length; i++) {
      final game = games[i];
      final ok = await _ensureContentReady(game, downloads, resPath);
      if (!ok) continue;

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
            data: '',
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
        await Db().db.gameDao.updateOrReplace(gameEntity);
      }
      currentGameNames.add(game.name);
    }

    final dbGames = await Db().db.gameDao.getByClassroomId(classroomId);
    for (var dbGame in dbGames) {
      if (!currentGameNames.contains(dbGame.name)) {
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

  /// 这本书 book 层有哪些字段块：'q'/'a'/'n' 各一个，提示按数组长度展开成 't'/'t1'/'t2'…
  /// 字体和提示服务配置都存在这些块里，两边都按这个列表遍历。
  static List<String> _fieldRefs(Map<String, dynamic> bookMap) {
    final ret = ['q', 'a', 'n'];
    final tipLength = VerseField.tipLength(bookMap);
    for (var i = 0; i < (tipLength == 0 ? 1 : tipLength); i++) {
      ret.add(VerseField.ref('t', i));
    }
    return ret;
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
    return await _ensureContentReady(entry, downloads, DocPath.getRelativePath(bookId));
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
    return await _ensureContentReady(entry, downloads, DocPath.getClassroomResRelativePath(classroomId));
  }

  /// [relativeFolder] 是这份资源所在的相对目录：书本资源给书本目录，
  /// 课堂级资源（游戏）给课堂资源目录。
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
