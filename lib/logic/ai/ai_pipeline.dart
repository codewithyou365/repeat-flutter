import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_lang.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';
import 'package:repeat_flutter/logic/ai/ai_model_paths.dart';
import 'package:repeat_flutter/logic/ai/infer_isolate.dart';

/// 按当前选中的模型装配推理 isolate 的初始化参数。
///
/// 录音页和复核页都要起推理 isolate，装配逻辑只写这一份。
class AiPipeline {
  /// 缺哪个角色就返回那个角色，调用方据此提示用户去下载；全齐了返回 null。
  static Future<AiRole?> missingRole(AiCatalog catalog) async {
    for (final role in [AiRole.asr, AiRole.mt, AiRole.tts]) {
      if (await AiModelHelp.selectedFor(role, catalog) == null) {
        return role;
      }
    }
    return null;
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
