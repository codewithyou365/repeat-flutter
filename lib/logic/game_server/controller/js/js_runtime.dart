import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_logic.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_logic.dart';
import 'package:repeat_flutter/logic/widget/game/game_state.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/logic/repeat_flow_for_browse.dart';
import 'package:repeat_flutter/page/repeat/logic/tts_helper.dart';
import 'package:repeat_flutter/page/repeat/repeat_logic.dart';

part 'js_code.dart';

class JsRuntime {
  final VoidCallback tapNext;
  final VoidCallback tapLeft;
  final VoidCallback tapRight;
  final VoidCallback tapMiddle;
  final VoidCallback longTapMiddle;
  final TtsHelper ttsHelper;

  JavascriptRuntime? _jsRuntime;
  bool _isInitialized = false;
  final SubList<int> subNewVerse = [];
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final Map<String, String> _sfxCache = {};

  JsRuntime({
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
      await invoke("Game.onNewVerse", {});
    });
    await loadDefaultCode();
    if (defaultCode.isNotEmpty) {
      coreJsCode = defaultCode;
    }
    _jsRuntime = getJavascriptRuntime();

    try {
      _jsRuntime!.onMessage('gameScoreInc', (dynamic args) async {
        final game = GameState.game;
        if (game == null) return 'no_active_game';
        if (args is! Map) return 'invalid_arguments';

        try {
          final userId = int.tryParse(args['userId']?.toString() ?? '');
          final score = int.tryParse(args['score']?.toString() ?? '0') ?? 0;
          final remark = args['remark']?.toString() ?? '';
          final gameId = game.id ?? 0;

          if (userId == null) return 'invalid_user_id';

          await Db().db.gameUserScoreDao.inc(
            userId,
            gameId,
            score,
            remark,
          );
          return '';
        } catch (e) {
          return e.toString();
        }
      });
      _jsRuntime!.onMessage('getUserName', (dynamic args) async {
        final game = GameState.game;
        if (game == null) return '';

        if (args is! Map) return '';

        final userIdRaw = args['userId'];

        if (userIdRaw == null) return '';

        try {
          final userId = int.parse(userIdRaw.toString());

          final String? name = await Db().db.gameUserDao.getUserNameById(userId);

          return name ?? '';
        } catch (e) {
          return '';
        }
      });
      _jsRuntime!.onMessage('broadcast', (dynamic args) {
        final game = GameState.game;
        if (game == null) return 'no_game';

        if (args is! Map) return 'invalid_args';

        final path = args['path'];
        final rawData = args['data'];

        if (path is! String) return 'invalid_path';

        try {
          final decodedData = rawData is String ? jsonDecode(rawData) : rawData;

          server.broadcast(message.Request(path: path, data: decodedData));

          return 'ok';
        } catch (e) {
          return 'error: ${e.toString()}';
        }
      });
      _jsRuntime!.onMessage('adminId', (dynamic args) {
        final game = GameState.game;
        if (game == null) {
          return '';
        }
        return '${GameState.adminId}';
      });
      _jsRuntime!.onMessage('adminEnable', (dynamic args) {
        final game = GameState.game;
        if (game == null) {
          return '';
        }
        return '${GameState.adminEnable}';
      });
      _jsRuntime!.onMessage('updateCurrVerseContent', (dynamic args) async {
        final game = GameState.game;
        if (game == null) return 'no_game';
        if (args is! Map) return 'invalid_args';

        try {
          final verseId = await Db().db.kvDao.getInt(K.lastVerseId) ?? 0;
          if (verseId == 0) return 'no_verse_id';

          final String type = args['type']?.toString() ?? '';
          final String newStr = args['content']?.toString() ?? '';

          if (type.isEmpty) return 'invalid_type';

          final verse = await Db().db.verseDao.getById(verseId);
          if (verse == null) return 'verse_not_found';

          Map<String, dynamic> contentMap = jsonDecode(verse.content);
          contentMap[type] = newStr;

          String jsonStr = jsonEncode(contentMap);
          await Db().db.verseDao.updateVerseContent(verseId, jsonStr);

          return 'ok';
        } catch (e) {
          return e.toString();
        }
      });

      // 逐字母朗读（拼读）时，如果用户开启了"拼读即置零"，把当前 verse 的学习等级重置为 0。
      // 复用 error() 逻辑：它会把 verse.progress 和今日进度都置 0，并刷新缓存/发事件，
      // 但不改动 examine 流程的 step 和 scheduled 顺序，用户可以继续打字。
      _jsRuntime!.onMessage('resetCurrVerseLevel', (dynamic args) async {
        final game = GameState.game;
        if (game == null) return 'no_game';
        try {
          final logic = Get.find<RepeatLogic>();
          // 浏览流(justView)不落今日计划库,置零无意义且会误改 Verse.progress,直接跳过
          if (logic.repeatFlow is RepeatFlowForBrowse) {
            return 'browse';
          }
          final curr = logic.getCurr();
          if (curr == null) return 'no_verse';
          await Db().db.scheduleDao.error(curr);
          return 'ok';
        } catch (e) {
          return e.toString();
        }
      });


      _jsRuntime!.onMessage('repeatFlow', (dynamic args) {
        final game = GameState.game;
        if (game == null) {
          return '';
        }
        final logic = Get.find<RepeatLogic>();
        final repeatFlow = logic.repeatFlow;
        if (repeatFlow == null) {
          return '';
        }
        if (repeatFlow is RepeatFlowForBrowse) {
          return 'browse';
        } else {
          return 'examine';
        }
      });
      _jsRuntime!.onMessage('uiLabel', (dynamic args) {
        final game = GameState.game;
        if (game == null) {
          return '';
        }
        if (args is! Map || !args.containsKey('name')) {
          return '';
        }
        final k = args['name'];
        if (k is! String) {
          return '';
        }
        final logic = Get.find<RepeatLogic>();
        switch (k) {
          case 'left':
            return logic.repeatFlow?.leftLabel ?? '';
          case 'right':
            return logic.repeatFlow?.rightLabel ?? '';
          case 'middle':
            return I18nKey.tips.tr;
          default:
            return '';
        }
      });
      _jsRuntime!.onMessage('uiTap', (dynamic args) {
        final game = GameState.game;
        if (game == null) {
          return 'error: game_not_initialized';
        }
        if (args is! Map) {
          return 'error: invalid_arguments';
        }
        final k = args['event'];
        if (k is! String) {
          return 'error: event_must_be_string';
        }
        switch (k) {
          case 'tapNext':
            tapNext();
            break;
          case 'tapLeft':
            tapLeft();
            break;
          case 'tapRight':
            tapRight();
            break;
          case 'tapMiddle':
            tapMiddle();
            break;
          case 'longTapMiddle':
            longTapMiddle();
            break;
          default:
            return 'error: unknown_event_type';
        }
        return 'success';
      });

      // 打字游戏的"辅助触控触发键"要在设置面板里列出可绑定的按钮，所以把复习页辅助触控当前显示的
      // 按钮（内置动作 + 用户自定义预设）导出成 [{id, name}]。id 形如 builtin:<枚举名> / custom:<行id>。
      // 注意：没走 uiTap 而是单开一条消息，因为 uiTap 是同步 handler，type.ts 里 Game.tap 依赖它同步
      // 返回 'success'，改成 async 会把 tapLeft/tapRight 全部变成"失败"。
      _jsRuntime!.onMessage('assistiveTouchActions', (dynamic args) async {
        final logic = _assistiveTouchLogic();
        if (logic == null) {
          return '[]';
        }
        // 用户刚在辅助触控里新建的预设也要能立刻选到，所以每次重新读一遍
        await logic.loadActions();
        final ret = <Map<String, dynamic>>[];
        for (final builtIn in logic.shownBuiltins) {
          ret.add({'id': 'builtin:${builtIn.name}', 'name': logic.labelOf(builtIn)});
        }
        for (final action in logic.actions) {
          // inputCount 是这个动作要几个参数（模版里实际写了几个 {{inputN}}），
          // inputKeys 是它们的占位符名字，脚本按这个顺序准备 assistiveTouchTap 的 'inputs'。
          final inputNumbers = ExpandLogic.inputNumbersOf(action.template);
          ret.add({
            'id': 'custom:${action.id}',
            'name': action.name,
            'inputCount': inputNumbers.length,
            'inputKeys': inputNumbers.map(ExpandLogic.inputKeyOf).toList(),
          });
        }
        return jsonEncode(ret);
      });

      // 取自定义动作上次执行时用的 input1（从作用位置存着的上次指令里反解出来），
      // 游戏的"单词累积提问"靠它在上次的基础上再加一个词。没有可反解的返回 ''。
      _jsRuntime!.onMessage('assistiveTouchLastInput', (dynamic args) async {
        if (args is! Map) {
          return '';
        }
        final id = args['id'];
        if (id is! String || !id.startsWith('custom:')) {
          return '';
        }
        final actionId = int.tryParse(id.substring('custom:'.length));
        if (actionId == null) {
          return '';
        }
        final logic = _assistiveTouchLogic();
        if (logic == null) {
          return '';
        }
        await logic.loadActions();
        final matched = logic.actions.where((e) => e.id == actionId);
        if (matched.isEmpty) {
          return '';
        }
        return logic.lastInput1Of(matched.first) ?? '';
      });

      // 玩家在打字页按下绑定键时执行对应的辅助触控按钮。
      // 动作已被删除返回 'not_found'；动作还在但当前复习模式下不可用（比如 examine 模式下的
      // deleteVerse）返回 'unavailable'，由网页端提示用户，而不是静默无反应。
      _jsRuntime!.onMessage('assistiveTouchTap', (dynamic args) async {
        if (args is! Map) {
          return 'invalid_args';
        }
        final id = args['id'];
        if (id is! String || id.isEmpty) {
          return 'invalid_args';
        }
        final logic = _assistiveTouchLogic();
        if (logic == null) {
          return 'not_found';
        }
        if (id.startsWith('builtin:')) {
          final name = id.substring('builtin:'.length);
          // 枚举名可能因为改代码对不上，用 where 查而不是 byName，避免抛异常
          final matched = BuiltInAction.values.where((e) => e.name == name);
          if (matched.isEmpty) {
            return 'not_found';
          }
          final builtIn = matched.first;
          if (!logic.shownBuiltins.contains(builtIn)) {
            return 'unavailable';
          }
          await logic.executeBuiltIn(builtIn);
          return 'ok';
        }
        if (id.startsWith('custom:')) {
          final actionId = int.tryParse(id.substring('custom:'.length));
          if (actionId == null) {
            return 'not_found';
          }
          await logic.loadActions();
          final matched = logic.actions.where((e) => e.id == actionId);
          if (matched.isEmpty) {
            return 'not_found';
          }
          // 带参数的动作从游戏调用时一律不弹框（弹 sheet 会打断打字），参数由脚本自己控制：
          // 'inputs' 按位置对应 input1..inputN，不传就是全空，传的比参数数量少也按空字符串补。
          final rawInputs = args['inputs'];
          if (rawInputs != null && rawInputs is! List) {
            return 'invalid_args';
          }
          final inputs = (rawInputs as List?)?.map((e) => e?.toString() ?? '').toList() ?? const <String>[];
          await logic.executeAction(matched.first, inputs: inputs);
          return 'ok';
        }
        return 'not_found';
      });

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
      _jsRuntime!.onMessage('tts', (dynamic args) async {
        if (args is! Map) {
          return 'invalid_args';
        }
        final payload = args.cast<String, dynamic>();
        final type = payload['type'];
        final text = payload['text'];
        final rateRaw = payload['rate'];
        final double? rate = rateRaw is num ? rateRaw.toDouble() : null;
        if (type is! String || type.isEmpty) {
          return 'invalid_type';
        }
        if (text is! String) {
          return 'invalid_text';
        }
        if (text.isEmpty) {
          return 'empty';
        }
        // 提示是多条的，JS 那边可以传 't1'/'t2' 指定第几条；TTS 配置按字段的大类走。
        final qaType = QaType.fromAcronym(VerseField.baseOf(type));
        if (qaType == null) {
          return 'invalid_text';
        }
        // 用户在界面上主动点击播放(而非自动朗读)时,同步取消"不自动播放媒体"标记,
        // 与音频/视频卡片点击播放按钮的行为保持一致
        if (payload['manual'] == true) {
          Get.find<RepeatLogic>().state.helper.doNotPlayMedia = false;
        }
        await ttsHelper.speakText(qaType.ttsKeys, text, rate: rate);
        return 'ok';
      });
      _jsRuntime!.onMessage('playWrong', (dynamic args) async {
        if (args is! Map) {
          return 'invalid_args';
        }
        final url = args['url'];
        if (url is! String || url.isEmpty) {
          return 'invalid_url';
        }
        try {
          var localPath = _sfxCache[url];
          if (localPath == null || !await File(localPath).exists()) {
            // 游戏服务器是自签名 HTTPS(仅 WebView 的 onReceivedServerTrustAuthRequest
            // 信任了该证书),just_audio 底层走系统播放器直连该证书会被拒绝(Source error),
            // 所以这里手动下载字节后落地临时文件,再让 just_audio 播放本地文件。
            final client = HttpClient()..badCertificateCallback = (cert, host, port) => true;
            final httpRequest = await client.getUrl(Uri.parse(url));
            final response = await httpRequest.close();
            if (response.statusCode != 200) {
              client.close();
              print("❌ playWrong failed for url=$url: HTTP ${response.statusCode}");
              return 'error';
            }
            final builder = BytesBuilder();
            await for (final chunk in response) {
              builder.add(chunk);
            }
            final bytes = builder.takeBytes();
            client.close();
            final tempDir = await getTemporaryDirectory();
            localPath = '${tempDir.path}/sfx_${url.hashCode}.wav';
            await File(localPath).writeAsBytes(bytes, flush: true);
            _sfxCache[url] = localPath;
          }
          await _sfxPlayer.stop();
          await _sfxPlayer.setFilePath(localPath);
          await _sfxPlayer.play();
        } catch (e) {
          print("❌ playWrong failed for url=$url: $e");
          return 'error';
        }
        return 'ok';
      });
      _jsRuntime!.onMessage('setData', (dynamic args) async {
        final game = GameState.game;
        if (game == null) {
          return '';
        }
        final String data = jsonEncode(args);
        await Db().db.gameDao.setData(game.id ?? 0, data);
        return '';
      });
      _jsRuntime!.onMessage('getData', (dynamic args) async {
        final game = GameState.game;
        if (game == null) {
          return '{}';
        }

        try {
          final ret = await Db().db.gameDao.getData(game.id ?? 0);
          return ret?.toString() ?? '{}';
        } catch (e) {
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
    } catch (e) {
      dispose(); // 初始化失败时及时清理
      rethrow;
    }
  }

  /// 复习页的辅助触控。游戏没开、或复习页已经退出（RepeatLogic 没注册）时返回 null，
  /// 让调用方按"没有可用按钮"处理，而不是抛异常把 JS 调用打断。
  AssistiveTouchLogic? _assistiveTouchLogic() {
    if (GameState.game == null || !Get.isRegistered<RepeatLogic>()) {
      return null;
    }
    return Get.find<RepeatLogic>().assistiveTouchLogic;
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
      JsEvalResult finalResult = evalResult;

      // 2. 如果是 Promise，handlePromise 会等待它完成并返回最终 JsEvalResult
      try {
        finalResult = await _jsRuntime!.handlePromise(evalResult, timeout: const Duration(seconds: 5));
        // 如果超时或不是 promise，会抛异常或直接返回原值（视实现），所以用 try/catch 包裹
      } catch (e) {
        // 超时或不是 Promise：按原结果继续（并记录）
        print("⚠️ handlePromise warning / timeout / not-a-promise: $e");
      }
      print("DEBUG: [Dart] JS 执行结果文本: ${evalResult.stringResult}");
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
      subNewVerse.off();
      _sfxPlayer.dispose();
      // 释放 C/C++ 层的内存资源，防止长时间运行导致 OOM
      _jsRuntime!.dispose();
      _jsRuntime = null;
      _isInitialized = false;
      print("🛑 JS Runtime disposed and memory freed.");
    }
  }
}
