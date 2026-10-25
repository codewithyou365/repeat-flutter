import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/js_bridge/js_bridge.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/widget/tip/tip_state.dart' show TipState;
import 'package:repeat_flutter/page/repeat/logic/tts_helper.dart';

part 'js_code.dart';

class JsRuntime {
  final VoidCallback tapNext;
  final VoidCallback tapLeft;
  final VoidCallback tapRight;
  final VoidCallback tapMiddle;
  final VoidCallback longTapMiddle;
  final TtsHelper ttsHelper;
  final bool Function() isMute;

  JavascriptRuntime? _jsRuntime;
  bool _isInitialized = false;
  final SubList<int> subNewVerse = [];

  JsRuntime({
    required this.isMute,
    required this.ttsHelper,
    required this.tapNext,
    required this.tapLeft,
    required this.tapRight,
    required this.tapMiddle,
    required this.longTapMiddle,
  });

  Future<void> init(String coreJsCode, Server server) async {
    if (_isInitialized) return;
    subNewVerse.on([EventTopic.newVerse], (verseId) async {
      await invoke("Tip.onNewVerse", {});
    });
    await loadDefaultCode();
    if (defaultCode.isNotEmpty) {
      coreJsCode = defaultCode;
    }
    _jsRuntime = getJavascriptRuntime();

    try {
      JsBridge(
        active: () => TipState.tip != null,
        ttsHelper: ttsHelper,
        tapNext: tapNext,
        tapLeft: tapLeft,
        tapRight: tapRight,
        tapMiddle: tapMiddle,
        longTapMiddle: longTapMiddle,
      ).register(_jsRuntime!);
      // 这个提示服务挂在哪个字段上（'q'/'a'/'n'/'t'/'t1'…）。contentKey 只带字段大类（'T'），
      // 提示有好几条时网页得靠它才知道读第几条。
      _jsRuntime!.onMessage('tipField', (dynamic args) {
        return TipState.tip?.t ?? '';
      });

      // 「单词提问并朗读」页删一个重点词：{field, word, prefix}。这个词问过的每一条都删，
      // 正文摘要按剩下的词重写成 "[prefix]: 词1, 词2"，一个不剩就清空正文。
      _jsRuntime!.onMessage('removeAskWord', (dynamic args) async {
        if (TipState.tip == null) return 'no_game';
        if (args is! Map) return 'invalid_args';
        final field = args['field']?.toString() ?? '';
        final word = args['word']?.toString() ?? '';
        final prefix = args['prefix']?.toString() ?? '';
        if (field.isEmpty || word.isEmpty) return 'invalid_args';
        try {
          final verseId = await Db().db.kvDao.getInt(K.lastVerseId) ?? 0;
          if (verseId == 0) return 'no_verse_id';
          final verse = await Db().db.verseDao.getById(verseId);
          if (verse == null) return 'verse_not_found';
          final Map<String, dynamic> contentMap = jsonDecode(verse.content);
          final words = VerseField.removeAskWord(contentMap, field, word);
          VerseField.setText(contentMap, field, words.isEmpty ? null : '$prefix: ${words.join(', ')}');
          await Db().db.verseDao.updateVerseContent(verseId, jsonEncode(contentMap));
          return 'ok';
        } catch (e) {
          return e.toString();
        }
      });

      _jsRuntime!.onMessage('isMute', (dynamic args) {
        return isMute().toString();
      });

      final result = _jsRuntime!.evaluate(coreJsCode);
      if (result.isError) {
        throw Exception("JS Engine Initialization Failed: ${result.stringResult}");
      }
      _isInitialized = true;
    } catch (e) {
      dispose(); // 初始化失败时及时清理
      rethrow;
    }
  }

  Future<dynamic> invoke(String methodName, Map<String, dynamic> payload) async {
    if (!_isInitialized || _jsRuntime == null) {
      throw Exception("JS Runtime is not initialized.");
    }
    return JsBridge.invoke(_jsRuntime!, methodName, payload);
  }

  /// 3. 析构代码 (非常重要：释放底层内存)
  void dispose() {
    if (_jsRuntime != null) {
      subNewVerse.off();
      // 释放 C/C++ 层的内存资源，防止长时间运行导致 OOM
      _jsRuntime!.dispose();
      _jsRuntime = null;
      _isInitialized = false;
      print("🛑 JS Runtime disposed and memory freed.");
    }
  }
}
