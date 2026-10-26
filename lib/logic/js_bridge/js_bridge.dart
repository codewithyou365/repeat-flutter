import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_logic.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/at_action.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/logic/repeat_flow_for_browse.dart';
import 'package:repeat_flutter/page/repeat/logic/tts_helper.dart';
import 'package:repeat_flutter/page/repeat/repeat_logic.dart';

/// 游戏和提示服务两个 JS 运行时共用的桥接口：不带任何具体玩法的语义，
/// 只提供"读写当前小节、复习页状态和按钮、朗读"这些 App 能力。
/// 只给某一边用的接口（游戏的积分/录音/键值表，提示的 tipField…）仍留在各自的 runtime 里。
class JsBridge {
  /// 这个运行时当前有没有挂着游戏/提示。没挂着时读接口返回空、写接口返回 'no_game'。
  final bool Function() active;
  final TtsHelper ttsHelper;
  final VoidCallback tapNext;
  final VoidCallback tapLeft;
  final VoidCallback tapRight;
  final VoidCallback tapMiddle;
  final VoidCallback longTapMiddle;

  /// 复习页的辅助触控，按动作 id 找动作用（朗读动作、联网动作）。不传或返回 null 就是这些接口不可用。
  final AssistiveTouchLogic? Function()? assistiveTouch;

  JsBridge({
    required this.active,
    required this.ttsHelper,
    required this.tapNext,
    required this.tapLeft,
    required this.tapRight,
    required this.tapMiddle,
    required this.longTapMiddle,
    this.assistiveTouch,
  });

  void register(JavascriptRuntime rt) {
    rt.onMessage('updateCurrVerseContent', (dynamic args) async {
      if (!active()) return 'no_game';
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

    rt.onMessage('repeatFlow', (dynamic args) {
      if (!active()) {
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
    rt.onMessage('uiLabel', (dynamic args) {
      if (!active()) {
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
    // 必须是同步 handler：type.ts 里 Game.tap 依赖它同步返回 'success'。
    rt.onMessage('uiTap', (dynamic args) {
      if (!active()) {
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

    rt.onMessage('getVerse', (dynamic args) async {
      if (!active()) {
        return '';
      }
      final verseId = await Db().db.kvDao.getInt(K.lastVerseId) ?? 0;
      final verse = await Db().db.scheduleDao.getVerseShowById(verseId);
      if (verse == null) {
        return '';
      }
      return verse.verseContent;
    });

    rt.onMessage('tts', (dynamic args) async {
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
      // 指定了朗读动作('custom:<id>')就用那个动作自己那套 TTS 配置（引擎/语言/音色/语速/音高）来读，
      // 读的还是这里传进来的文本（打字游戏的当前单词），跟动作模版无关。
      // 动作找不到了（被删/改了类型）就当没指定，按字段的公共配置读，不让游戏这边直接哑掉。
      final settings = await ttsSettingsOf(payload['action']);
      if (settings != null) {
        await ttsHelper.speakTextWith(settings, text);
        return 'ok';
      }
      await ttsHelper.speakText(qaType.ttsKeys, text, rate: rate);
      return 'ok';
    });

    // ---- 读写当前小节 ----
    // 写之前都要带上读时拿到的 version（整份内容的 sha1），对不上返回 'conflict'，
    // 由 JS 重新 verseGet 再改：读和写之间 App 或别的游戏可能已经改过这一节。

    // {} -> {verseId, version, content}，content 是整份小节 JSON。没挂着/没有当前小节返回 {}。
    rt.onMessage('verseGet', (dynamic args) async {
      if (!active()) return '{}';
      final verse = await _currVerse();
      if (verse == null) return '{}';
      return jsonEncode({
        'verseId': verse.id,
        'version': versionOf(verse.content),
        'content': jsonDecode(verse.content),
      });
    });

    // {ref, version, set?, remove?, text?} -> 'ok' / 'conflict' / 错误码。规则见 VerseField.patchField：
    // set/remove 不能碰 App 的键；带了 text 这个键（哪怕是 null）才换正文。
    rt.onMessage('fieldPatch', (dynamic args) async {
      if (!active()) return 'no_game';
      if (args is! Map) return 'invalid_args';
      final ref = args['ref'];
      final set = args['set'];
      final remove = args['remove'];
      final text = args['text'];
      if (ref is! String || (set != null && set is! Map) || (remove != null && remove is! List) || (text != null && text is! String)) {
        return 'invalid_args';
      }
      return await _write(args['version'], (content) {
        return VerseField.patchField(
          content,
          ref,
          set: set == null ? null : Map<String, dynamic>.from(set),
          remove: remove?.map((e) => '$e').toList(),
          setText: args.containsKey('text'),
          text: text,
        );
      });
    });

    // {version, key, value} -> 'ok' / 'conflict' / 错误码。写小节顶层的游戏私有键（value 为 null 就是删），
    // 单字母键归 App 不让写。
    rt.onMessage('verseKeySet', (dynamic args) async {
      if (!active()) return 'no_game';
      if (args is! Map) return 'invalid_args';
      final key = args['key'];
      if (key is! String || key.isEmpty) return 'invalid_key';
      if (VerseField.isReservedTopKey(key)) return 'reserved_key:$key';
      return await _write(args['version'], (content) {
        final value = args['value'];
        if (value == null) {
          content.remove(key);
        } else {
          content[key] = value;
        }
        return null;
      });
    });

    // ---- 辅助触控里的动作 ----
    // 动作 id 跟 assistiveTouchActions 给的一样，形如 'custom:<动作id>'。

    // {id, inputs?} -> {instruction, target} 或 {error}：只渲染 net 动作的指令，不请求。
    // target 是结果该放进的字段（动作配的作用位置），instruction 可以拿去当缓存的 key。
    rt.onMessage('netRender', (dynamic args) async {
      if (args is! Map) return jsonEncode({'error': 'invalid_args'});
      final rawInputs = args['inputs'];
      if (rawInputs != null && rawInputs is! List) return jsonEncode({'error': 'invalid_args'});
      final found = await _netAction(args['id']);
      if (found.error != null) return jsonEncode({'error': found.error});
      final inputs = (rawInputs as List?)?.map((e) => e?.toString() ?? '').toList() ?? const <String>[];
      final instruction = await found.logic!.renderNet(found.action!, inputs);
      if (instruction == null) return jsonEncode({'error': 'no_verse'});
      return jsonEncode({'instruction': instruction, 'target': found.action!.target});
    });

    // {id, instruction} -> {text} 或 {error}：拿指令请求 net 动作的服务，只返回结果，不写库不朗读。
    // 请求要等大模型，JS 那边调用它的方法记得把超时放长（请求头 jsTimeoutMs）。
    rt.onMessage('netSend', (dynamic args) async {
      if (args is! Map) return jsonEncode({'error': 'invalid_args'});
      final instruction = args['instruction'];
      if (instruction is! String || instruction.isEmpty) return jsonEncode({'error': 'invalid_args'});
      final found = await _netAction(args['id']);
      if (found.error != null) return jsonEncode({'error': found.error});
      final text = await found.logic!.sendNet(found.action!, instruction);
      if (text == null || text.isEmpty) return jsonEncode({'error': 'empty'});
      return jsonEncode({'text': text});
    });

    // {id, text} -> 'ok' / 'not_found' / 'empty'：用某个朗读动作的 TTS 配置读 text。
    // 跟 tts 带 action 不同：动作找不到就不读，不回落到字段的公共配置。
    rt.onMessage('ttsWith', (dynamic args) async {
      if (args is! Map) return 'invalid_args';
      final text = args['text'];
      if (text is! String || text.isEmpty) return 'empty';
      final settings = await ttsSettingsOf(args['id']);
      if (settings == null) return 'not_found';
      await ttsHelper.speakTextWith(settings, text);
      return 'ok';
    });
  }

  /// 小节内容的版本号：整份内容串的 sha1。不存库，读的时候现算。
  static String versionOf(String content) => sha1.convert(utf8.encode(content)).toString();

  static Future<Verse?> _currVerse() async {
    final verseId = await Db().db.kvDao.getInt(K.lastVerseId) ?? 0;
    if (verseId == 0) return null;
    return await Db().db.verseDao.getById(verseId);
  }

  /// 从库里重新读当前小节、核对版本、交给 [apply] 改，改成功了整份写回。
  /// [apply] 返回错误码就原样返回，不写库。
  static Future<String> _write(Object? version, String? Function(Map<String, dynamic> content) apply) async {
    if (version is! String || version.isEmpty) return 'invalid_version';
    try {
      final verse = await _currVerse();
      if (verse == null) return 'no_verse';
      if (versionOf(verse.content) != version) return 'conflict';
      final Map<String, dynamic> content = jsonDecode(verse.content);
      final error = apply(content);
      if (error != null) return error;
      await Db().db.verseDao.updateVerseContent(verse.id!, jsonEncode(content));
      return 'ok';
    } catch (e) {
      return e.toString();
    }
  }

  /// 'custom:<动作id>' -> 动作。找不到、类型不对、当前复习模式下不可用时 error 有值。
  Future<({AssistiveTouchLogic? logic, AtAction? action, String? error})> _action(Object? id, AtActionType type) async {
    if (id is! String || !id.startsWith('custom:')) {
      return (logic: null, action: null, error: 'not_found');
    }
    final actionId = int.tryParse(id.substring('custom:'.length));
    final logic = assistiveTouch?.call();
    if (actionId == null || logic == null) {
      return (logic: null, action: null, error: 'not_found');
    }
    await logic.loadActions();
    final matched = logic.actions.where((e) => e.id == actionId && e.type == type);
    if (matched.isEmpty) {
      return (logic: null, action: null, error: 'not_found');
    }
    return (logic: logic, action: matched.first, error: null);
  }

  Future<({AssistiveTouchLogic? logic, AtAction? action, String? error})> _netAction(Object? id) async {
    final found = await _action(id, AtActionType.net);
    if (found.error == null && !found.logic!.availableForFlow(found.action!)) {
      return (logic: null, action: null, error: 'unavailable');
    }
    return found;
  }

  /// 'custom:<朗读动作id>' -> 那个朗读动作存的 TTS 配置。
  /// 没传、不是朗读类型、动作已经不在了，一律返回 null（调用方按"没指定"处理）。
  Future<TtsSettings?> ttsSettingsOf(Object? id) async {
    final found = await _action(id, AtActionType.tts);
    return found.action?.tts.settings;
  }

  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration maxTimeout = Duration(seconds: 120);

  /// 网页请求头 'jsTimeoutMs' 指定这次调用等多久（要等大模型的方法用），没给或给错了用 [defaultTimeout]，
  /// 最长 [maxTimeout]。网页那边 ws 自己的超时也得跟着放长，不然它先放弃了。
  static Duration timeoutOf(Object? ms) {
    final v = int.tryParse('${ms ?? ''}');
    if (v == null || v <= 0) return defaultTimeout;
    return Duration(milliseconds: v.clamp(1, maxTimeout.inMilliseconds));
  }

  /// 调 JS 里的 [methodName]（如 'Game.onNewVerse'），等它的 Promise 落定后把返回的 JSON 串解开。
  /// 超时、出错、返回的不是 JSON 一律返回 null。
  static Future<dynamic> invoke(JavascriptRuntime rt, String methodName, Map<String, dynamic> payload, {Duration timeout = defaultTimeout}) async {
    try {
      final jsonPayload = jsonEncode(payload);
      final jsCommand = "$methodName($jsonPayload);";

      // 1. 同步 evaluate（可能返回 Promise）
      final JsEvalResult evalResult = rt.evaluate(jsCommand);
      JsEvalResult finalResult = evalResult;

      // 2. 如果是 Promise，handlePromise 会等待它完成并返回最终 JsEvalResult
      try {
        finalResult = await rt.handlePromise(evalResult, timeout: timeout);
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

      // JS 那边一律用 JSON.stringify 返回字符串，这里直接 jsonDecode。
      return jsonDecode(resultString);
    } catch (e) {
      print("❌ JS invoke exception: $e");
      return null;
    }
  }
}
