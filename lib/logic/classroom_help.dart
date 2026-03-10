import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

class GameContent {
  int? id;
  String hash;
  String name;
  String key;

  GameContent({
    this.id,
    required this.hash,
    required this.name,
    required this.key,
  });

  factory GameContent.fromJson(Map<String, dynamic> json) {
    return GameContent(
      id: json['i'] as int?,
      hash: json['h'] ?? '',
      name: json['n'] ?? '',
      key: json['k'] ?? '',
    );
  }
}

class ClassroomHelp {
  static const fontAliasSuffix = "FontAlias";
  static const fontHashSuffix = "FontHash";
  static const fontSizeSuffix = "FontSize";
  static Map<int, String> savedVersionSigCacheMap = {};

  static Future<void> registerRes() async {
    try {
      var books = await Db().db.bookDao.getAll(Classroom.curr);
      String savedVersionSigCache = savedVersionSigCacheMap[Classroom.curr] ?? '';
      books.sort((a, b) => a.id!.compareTo(b.id!));
      var currentVersionSig = books.map((e) => '${e.id}:${e.contentVersion}').join(',');

      if (currentVersionSig == savedVersionSigCache) return;

      final rootPath = await DocPath.getContentPath();
      final Set<String> currentGameNames = {};

      for (var book in books) {
        if (book.content.isEmpty) continue;

        Map<String, dynamic> bookMap = jsonDecode(book.content);
        List<DownloadContent> downloads = DownloadContent.toList(bookMap['d']) ?? [];

        const prefixes = ['q', 't', 'a', 'n'];
        for (var prefix in prefixes) {
          String alias = bookMap['$prefix$fontAliasSuffix'] ?? '';
          String hash = bookMap['$prefix$fontHashSuffix'] ?? '';

          if (alias.isNotEmpty && hash.isNotEmpty) {
            final download = downloads.firstWhereOrNull((e) => e.hash == hash);
            if (download != null) {
              final localFolder = rootPath.joinPath(DocPath.getRelativePath(book.id!).joinPath(download.folder));
              final filePath = localFolder.joinPath(download.name);

              await registerCustomFont(alias, filePath);
            }
          }
        }
        savedVersionSigCacheMap[Classroom.curr] = currentVersionSig;
        final savedVersionSig = await Db().db.crKvDao.getStr(Classroom.curr, CrK.classroomResourceVersion);

        if (currentVersionSig == savedVersionSig) return;
        if (bookMap['g'] != null) {
          var gameData = bookMap['g'] as List<dynamic>;
          List<GameContent> games = gameData.map((e) => GameContent.fromJson(e)).toList();
          for (var i = 0; i < games.length; i++) {
            final game = games[i];
            if (game.name.isNotEmpty && game.hash.isNotEmpty) {
              final download = downloads.firstWhereOrNull((e) => e.hash == game.hash);
              if (download != null) {
                final localFolder = rootPath.joinPath(DocPath.getRelativePath(book.id!));
                final zipFilePath = localFolder.joinPath(download.folder).joinPath(download.name);
                final destinationDir = localFolder.joinPath(download.folder).joinPath(download.pureName);
                bool ok = await unzipGame(zipFilePath, destinationDir);
                if (ok) {
                  Game? gameEntity;
                  if (game.id != null) {
                    gameEntity = await Db().db.gameDao.getById(game.id!);
                    if (gameEntity == null || gameEntity.bookId != book.id!) {
                      gameEntity = null;
                    }
                  }
                  if (gameEntity == null) {
                    await Db().db.gameDao.insertOrReplace(
                      Game(
                        classroomId: Classroom.curr,
                        bookId: book.id!,
                        key: game.key,
                        name: game.name,
                        hash: game.hash,
                        data: '',
                        createTime: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                    gameData[i]['i'] = await Db().db.gameDao.getIdByName(Classroom.curr, game.name);
                  } else {
                    gameEntity.name = game.name;
                    gameEntity.hash = game.hash;
                    await Db().db.gameDao.updateOrReplace(gameEntity);
                  }
                  currentGameNames.add(game.name);
                }
              }
            }
          }
        }
        Db().db.bookDao.updateBookContent(book.id!, jsonEncode(bookMap));
      }
      final dbGames = await Db().db.gameDao.getByClassroomId(Classroom.curr);
      for (var dbGame in dbGames) {
        if (!currentGameNames.contains(dbGame.name)) {
          await Db().db.gameDao.deleteByName(Classroom.curr, dbGame.name);
        }
      }
      books = await Db().db.bookDao.getAll(Classroom.curr);
      books.sort((a, b) => a.id!.compareTo(b.id!));
      currentVersionSig = books.map((e) => '${e.id}:${e.contentVersion}').join(',');
      Db().db.crKvDao.insertOrReplace(
        CrKv(
          Classroom.curr,
          CrK.classroomResourceVersion,
          currentVersionSig,
        ),
      );
      savedVersionSigCacheMap[Classroom.curr] = currentVersionSig;
    } catch (e) {
      debugPrint("Error registering fonts: $e");
    }
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
