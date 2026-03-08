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
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

class GameContent {
  String hash;
  String name;

  GameContent({required this.hash, required this.name});

  factory GameContent.fromJson(Map<String, dynamic> json) {
    return GameContent(
      hash: json['hash'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class ClassroomHelp {
  static const fontAliasSuffix = "FontAlias";
  static const fontHashSuffix = "FontHash";
  static const fontSizeSuffix = "FontSize";

  static Future<void> registerRes() async {
    try {
      var books = await Db().db.bookDao.getAll(Classroom.curr);
      final rootPath = await DocPath.getContentPath();
      final Set<String> currentGameNames = {};

      for (var book in books) {
        if (book.content.isEmpty) continue;

        Map<String, dynamic> bookMap = jsonDecode(book.content);
        List<DownloadContent> downloads = DownloadContent.toList(bookMap['d']) ?? [];

        const prefixes = ["q", "t", "a", "n"];
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

        if (bookMap["game"] != null) {
          var gameData = bookMap["game"] as List<dynamic>;
          List<GameContent> games = gameData.map((e) => GameContent.fromJson(e)).toList();
          for (var game in games) {
            if (game.name.isNotEmpty && game.hash.isNotEmpty) {
              final download = downloads.firstWhereOrNull((e) => e.hash == game.hash);
              if (download != null) {
                final localFolder = rootPath.joinPath(DocPath.getRelativePath(book.id!));
                final zipFilePath = localFolder.joinPath(download.folder).joinPath(download.name);
                final destinationDir = localFolder.joinPath(download.folder).joinPath(download.pureName);
                bool ok = await unzipGame(zipFilePath, destinationDir);
                if (ok) {
                  await Db().db.gameDao.insertOrReplace(
                    Game(
                      classroomId: Classroom.curr,
                      bookId: book.id!,
                      name: game.name,
                      hash: game.hash,
                      ownerUserId: 0,
                      createTime: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                  currentGameNames.add(game.name);
                }
              }
            }
          }
        }
      }

      final dbGames = await Db().db.gameDao.getByClassroomId(Classroom.curr);
      for (var dbGame in dbGames) {
        if (!currentGameNames.contains(dbGame.name)) {
          await Db().db.gameDao.deleteByName(Classroom.curr, dbGame.name);
        }
      }
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
