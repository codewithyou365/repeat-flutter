import 'dart:convert';

import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'constant.dart';
import 'game.dart';

class WordSlicerUtils {
  static Future<int> getMaxScore() async {
    var ret = await Db().db.crKvDao.getInt(Classroom.curr, CrK.wordSlicerGameForMaxScore);
    return ret ?? 10;
  }

  static Future<int> getHiddenContentPercent() async {
    var ret = await Db().db.crKvDao.getInt(Classroom.curr, CrK.wordSlicerGameForHiddenContentPercent);
    return ret ?? 0;
  }

  static String? getText(int verseId) {
    final verse = VerseHelp.getCache(verseId);
    if (verse == null) {
      return null;
    }
    final verseMap = jsonDecode(verse.verseContent);
    String result = verseMap[MapKeyEnum.wordSlicerText.name] ?? '';
    if (result.isNotEmpty) {
      return result;
    }
    return verseMap['a'] ?? '';
  }

  static Future<Map<String, String>> getHeaders(int userId) async {
    int editorUserId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.wordSlicerGameForEditorUserId) ?? 0;
    if (editorUserId == userId) {
      Map<String, String> headers = {};
      final text = WordSlicerUtils.getText(wordSlicerGame.verseId);
      if (text == null) {
        return headers;
      }
      headers["editorContent"] = text;
      headers["editorEnable"] = "1";
      return headers;
    }
    return {};
  }
}
