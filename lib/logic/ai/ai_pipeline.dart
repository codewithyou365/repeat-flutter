import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_lang.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';
import 'package:repeat_flutter/logic/ai/ai_model_paths.dart';
import 'package:repeat_flutter/logic/ai/ai_remote.dart';
import 'package:repeat_flutter/logic/ai/infer_engine.dart';
import 'package:repeat_flutter/logic/ai/infer_isolate.dart';

/// 按当前选中的模型装配推理 isolate 的初始化参数。
///
/// 录音页和复核页都要起推理 isolate，装配逻辑只写这一份。
class AiPipeline {
  /// 缺哪个角色就返回那个角色，调用方据此提示用户去下载；全齐了返回 null。
  ///
  /// 开了远程推理就一概不拦：模型装在电脑上，手机这边一个都没有也是正常用法。
  static Future<AiRole?> missingRole(AiCatalog catalog) async {
    if (await AiRemote.enabled()) {
      return null;
    }
    return await missingLocalRole(catalog);
  }

  /// 开录前的把关：还缺哪些角色的模型。
  ///
  /// VAD 单拎出来永远按本机算：它决定"切好一句"的震动反馈时机，必须实时，
  /// 不可能挪到远程去。其余三个开了远程就不拦——模型在电脑上。
  static Future<List<AiRole>> missingRoles(AiCatalog catalog) async {
    final out = <AiRole>[];
    if (await AiModelHelp.selectedFor(AiRole.vad, catalog) == null) {
      out.add(AiRole.vad);
    }
    if (await AiRemote.enabled()) {
      return out;
    }
    for (final role in [AiRole.asr, AiRole.mt, AiRole.tts]) {
      if (await AiModelHelp.selectedFor(role, catalog) == null) {
        out.add(role);
      }
    }
    return out;
  }

  /// 机内缺哪个角色。和 [missingRole] 的区别是它不看远程开关——
  /// 装配引擎时要靠它判断"还有没有本地这条后路"。
  static Future<AiRole?> missingLocalRole(AiCatalog catalog) async {
    for (final role in [AiRole.asr, AiRole.mt, AiRole.tts]) {
      if (await AiModelHelp.selectedFor(role, catalog) == null) {
        return role;
      }
    }
    return null;
  }

  /// 按当前设置造一个推理引擎。录音页和复核页都走这里。
  ///
  /// 三种形态：
  /// - 远程关：机内 isolate，跟以前一模一样
  /// - 远程开 + 机内模型齐：远程优先，服务端挂了自动切回本地
  /// - 远程开 + 机内没模型：只有远程，挂了这一段就是失败（复核页可重跑）
  ///
  /// 返回 null 表示两条路都走不通，调用方去提示用户下模型。
  static Future<InferEngine?> createEngine(
    AiCatalog catalog, {
    void Function()? onFellBack,
  }) async {
    final build = await prepare(catalog);
    if (!await AiRemote.enabled()) {
      return build == null ? null : await LocalInferEngine.start(build);
    }

    final baseUrl = await AiRemote.url();
    final params = await remoteParams(catalog);
    if (build == null) {
      return RemoteInferEngine(baseUrl: baseUrl, params: params);
    }
    return FallbackInferEngine(
      baseUrl: baseUrl,
      params: params,
      buildLocal: build,
      onFellBack: onFellBack,
    );
  }

  /// 远程请求里手机说了算的那部分：只有语言。
  ///
  /// 用哪个模型由服务端决定（见 [AiRemoteParams] 的说明），所以这里不再挑模型。
  ///
  /// 语言要按**本机选中的识别模型**过一遍 [AiLang.effective]：存的值可能是换模型
  /// 之前选的，本机模型不支持就退回自动。本机一个模型都没有时不过滤，原样送上去
  /// ——服务端的模型支持什么由服务端说了算。
  static Future<AiRemoteParams> remoteParams(AiCatalog catalog) async {
    final lang = await AiLang.current();
    final asr = await AiModelHelp.selectedFor(AiRole.asr, catalog);
    return AiRemoteParams(language: asr == null ? lang : AiLang.effective(asr, lang));
  }

  /// 返回一个能拿 SendPort 造出 [InferInit] 的闭包；缺模型则返回 null。
  ///
  /// 之所以返回闭包而不是直接返回 InferInit：SendPort 要等 [InferIsolate.start]
  /// 建好 ReceivePort 才拿得到。
  static Future<InferInit Function(SendPort)?> prepare(AiCatalog catalog) async {
    final asr = await AiModelHelp.selectedFor(AiRole.asr, catalog);
    final mt = await AiModelHelp.selectedFor(AiRole.mt, catalog);
    final tts = await AiModelHelp.selectedFor(AiRole.tts, catalog);
    if (asr == null || mt == null || tts == null) {
      return null;
    }

    final asrDir = await AiModelHelp.dirOf(asr.id);
    final mtDir = await AiModelHelp.dirOf(mt.id);
    final ttsDir = await AiModelHelp.dirOf(tts.id);

    // 用户钉死的识别语言。翻译那一份也要钉：whisper 的 translate 任务里
    // language 说的是**源语言**，不给的话它照样要先猜一遍，猜错了译文就跟着错。
    final lang = await AiLang.current();
    final asrCfg = withAsrLanguage(AiModelPaths.resolve(asr.cfg, asrDir), AiLang.effective(asr, lang));
    // 翻译那一份 config 必须把 task 改成 translate。清单里存的是 transcribe，
    // 因为同一份 whisper 既当识别又当翻译，两种用法只差这一个字段。
    final mtCfg = withWhisperTask(
      withAsrLanguage(AiModelPaths.resolve(mt.cfg, mtDir), AiLang.effective(mt, lang)),
      'translate',
    );
    final ttsCfg = AiModelPaths.resolve(tts.cfg, ttsDir);

    // 说话人 id。多说话人模型（vits-zh-aishell3 有 174 个）才有意义，
    // 默认的 melo-tts 只有一个，取 0。
    final sid = await Db().db.crKvDao.getInt(Classroom.curr, CrK.aiTtsSpeakerId) ?? 0;

    return (SendPort port) => InferInit(
          port: port,
          asrCfg: asrCfg,
          mtCfg: mtCfg,
          ttsCfg: ttsCfg,
          // 同一个模型 id 才共用 recognizer 实例，不然 whisper-small 会被加载两遍
          shareRecognizer: asr.id == mt.id,
          ttsSid: sid,
        );
  }

  /// 深拷一份并把识别语言写进去，不改原 map（理由同 [withWhisperTask]）。
  ///
  /// lang 为空（自动判断）时**原样返回**：清单里那几个只认一门语言的模型
  /// （whisper-small.en 之类）自己就把 language 写死了，用空串盖掉等于把它废了。
  @visibleForTesting
  static Map<String, dynamic> withAsrLanguage(Map<String, dynamic> cfg, String lang) {
    if (lang.isEmpty) {
      return cfg;
    }
    final out = Map<String, dynamic>.from(cfg);
    final model = out['model'];
    if (model is! Map<String, dynamic>) {
      return out;
    }
    final newModel = Map<String, dynamic>.from(model);
    // 只有这两种模型认 language；paraformer 这种单语模型没这个字段，写进去 sherpa 也不看
    for (final key in ['whisper', 'senseVoice']) {
      final sub = newModel[key];
      if (sub is Map<String, dynamic> && sub.isNotEmpty) {
        newModel[key] = Map<String, dynamic>.from(sub)..['language'] = lang;
      }
    }
    out['model'] = newModel;
    return out;
  }

  /// 深拷一份并把 model.whisper.task 换掉，不改原 map。
  ///
  /// 两个都要命：
  /// 1. 就地改会污染缓存里的 catalog，下一次装配拿到的 asrCfg 就变成 translate 了，
  ///    表现是"原文那一栏也是英文"——不报错，只是结果全错。
  /// 2. 浅拷不够，得把 model 和 model.whisper 两层都拷开，否则改的还是同一个子 map。
  @visibleForTesting
  static Map<String, dynamic> withWhisperTask(Map<String, dynamic> cfg, String task) {
    final out = Map<String, dynamic>.from(cfg);
    final model = out['model'];
    if (model is! Map<String, dynamic>) {
      return out;
    }
    final newModel = Map<String, dynamic>.from(model);
    final whisper = newModel['whisper'];
    if (whisper is Map<String, dynamic>) {
      newModel['whisper'] = Map<String, dynamic>.from(whisper)..['task'] = task;
    }
    out['model'] = newModel;
    return out;
  }
}
