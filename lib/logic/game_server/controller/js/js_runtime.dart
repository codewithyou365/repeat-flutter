import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/game/game_state.dart';

String defaultCode = '';

class JsRuntime {
  JavascriptRuntime? _jsRuntime;
  bool _isInitialized = false;

  /// 1. 初始化 (预热 JS 引擎并加载核心逻辑)
  Future<void> init(String coreJsCode) async {
    if (defaultCode.isNotEmpty) {
      coreJsCode = defaultCode;
    }
    if (_isInitialized) return;

    _jsRuntime = getJavascriptRuntime();

    try {
      _jsRuntime!.onMessage('getVerse', (dynamic args) async {
        final game = GameState.game;
        if (game == null) {
          return '';
        }
        final verseId = await Db().db.kvDao.getInt(K.lastVerseId) ?? 0;
        final verse = VerseHelp.getCache(verseId);
        if (verse == null) {
          return '';
        }
        return verse.verseContent;
      });
      _jsRuntime!.onMessage('setData', (dynamic args) async {
        final game = GameState.game;
        if (game == null) {
          return '';
        }
        final String data = args['data'];
        await Db().db.gameDao.setData(game.id ?? 0, data);
        return '';
      });
      _jsRuntime!.onMessage('getData', (dynamic args) async {
        // 使用醒目的标记，方便你在控制台刷新的海量日志中一眼看到它
        print("🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥");
        print("DEBUG: [Dart] ⚡ 收到 JS 的 'getData' 请求! ⚡");
        print("DEBUG: [Dart] ⚡ 接收到的 args: $args");
        print("🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥");

        final game = GameState.game;
        if (game == null) {
          print("DEBUG: [Dart] ❌ GameState.game 为 null");
          return '{}';
        }

        try {
          print("DEBUG: [Dart] 正在查询数据库: gameId = ${game.id}");
          final ret = await Db().db.gameDao.getData(game.id ?? 0);
          print("DEBUG: [Dart] 数据库查询结果: $ret");

          // 确保返回的是 String
          return ret?.toString() ?? '{}';
        } catch (e) {
          print("DEBUG: [Dart] ❌ 数据库查询异常: $e");
          return '{}';
        }
      });
      // 执行初始化的 JS 代码（比如声明全局对象、加载分词算法等）
      // 这一步只在 Server 启动或 App 初始化时执行一次
      final result = _jsRuntime!.evaluate(coreJsCode);
      if (result.isError) {
        throw Exception("JS Engine Initialization Failed: ${result.stringResult}");
      }
      _isInitialized = true;
      print("🚀 JS Runtime initialized successfully.");
    } catch (e) {
      print("❌ JS Runtime init error: $e");
      dispose(); // 初始化失败时及时清理
      rethrow;
    }
  }

  Future<dynamic> invoke(String methodName, Map<String, dynamic> payload) async {
    if (!_isInitialized || _jsRuntime == null) {
      throw Exception("JS Runtime is not initialized.");
    }

    try {
      final jsonPayload = jsonEncode(payload);
      final jsCommand = "$methodName($jsonPayload);";

      // 1. 同步 evaluate（可能返回 Promise）
      final JsEvalResult evalResult = _jsRuntime!.evaluate(jsCommand);
      print("DEBUG: [Dart] JS 执行初步结果文本: ${evalResult.stringResult}");

      JsEvalResult finalResult = evalResult;

      // 2. 如果是 Promise，handlePromise 会等待它完成并返回最终 JsEvalResult
      try {
        finalResult = await _jsRuntime!.handlePromise(evalResult, timeout: const Duration(seconds: 5));
        // 如果超时或不是 promise，会抛异常或直接返回原值（视实现），所以用 try/catch 包裹
      } catch (e) {
        // 超时或不是 Promise：按原结果继续（并记录）
        print("⚠️ handlePromise warning / timeout / not-a-promise: $e");
      }

      // 3. 检查错误
      if (finalResult.isError) {
        print("⚠️ JS Execution Error (final): ${finalResult.stringResult}");
        return null;
      }

      // 4. 解析最终字符串结果为 JSON
      final resultString = finalResult.stringResult;
      print("DEBUG: [Dart] JS 最终结果文本: $resultString");

      // 如果 JS 本来就返回了一个对象而非 JSON 字符串，你可能需要调整 JS 端，
      // 但你当前 JS 已用 JSON.stringify 返回字符串，因此下面直接 jsonDecode 就 OK。
      return jsonDecode(resultString);
    } catch (e) {
      print("❌ JS invoke exception: $e");
      return null;
    }
  }

  /// 3. 析构代码 (非常重要：释放底层内存)
  void dispose() {
    if (_jsRuntime != null) {
      // 释放 C/C++ 层的内存资源，防止长时间运行导致 OOM
      _jsRuntime!.dispose();
      _jsRuntime = null;
      _isInitialized = false;
      print("🛑 JS Runtime disposed and memory freed.");
    }
  }
}
