import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/ai/ai_pipeline.dart';

void main() {
  Map<String, dynamic> baseCfg() => {
        'model': {
          'whisper': {'encoder': 'e.onnx', 'decoder': 'd.onnx', 'task': 'transcribe', 'language': ''},
          'tokens': 't.txt',
          'provider': 'cpu',
        },
      };

  test('task 被换成 translate，其余字段不动', () {
    final out = AiPipeline.withWhisperTask(baseCfg(), 'translate');
    final whisper = (out['model'] as Map)['whisper'] as Map;
    expect(whisper['task'], 'translate');
    expect(whisper['encoder'], 'e.onnx');
    expect(whisper['decoder'], 'd.onnx');
    expect((out['model'] as Map)['tokens'], 't.txt');
    expect((out['model'] as Map)['provider'], 'cpu');
  });

  test('原 map 一个字节都不能被改到', () {
    // 这是最危险的一条：cfg 来自缓存的 catalog，就地改会让下一次装配的 asrCfg
    // 也变成 translate，于是"原文"那一栏也出英文——不报错，结果全错。
    final src = baseCfg();
    AiPipeline.withWhisperTask(src, 'translate');
    expect(((src['model'] as Map)['whisper'] as Map)['task'], 'transcribe');
  });

  test('两层都拷开了，改译文的不会牵动识别的', () {
    final src = baseCfg();
    final mt = AiPipeline.withWhisperTask(src, 'translate');
    // 浅拷的话这两个会是同一个子 map
    expect(identical(mt['model'], src['model']), isFalse);
    expect(identical((mt['model'] as Map)['whisper'], (src['model'] as Map)['whisper']), isFalse);
  });

  test('非 whisper 的 config 原样返回，不报错', () {
    final sense = {
      'model': {
        'senseVoice': {'model': 'm.onnx'},
        'tokens': 't.txt',
      },
    };
    final out = AiPipeline.withWhisperTask(sense, 'translate');
    expect((out['model'] as Map)['senseVoice'], isNotNull);
    expect((out['model'] as Map).containsKey('whisper'), isFalse);
  });

  test('形状不对的 config 不会抛异常', () {
    expect(AiPipeline.withWhisperTask({}, 'translate'), isEmpty);
    expect(AiPipeline.withWhisperTask({'model': 'nonsense'}, 'translate')['model'], 'nonsense');
  });

  test('识别语言写进 whisper 和 senseVoice，原 map 不动', () {
    final src = baseCfg();
    final out = AiPipeline.withAsrLanguage(src, 'zh');
    expect(((out['model'] as Map)['whisper'] as Map)['language'], 'zh');
    // 老规矩：cfg 来自缓存的 catalog，就地改会污染下一次装配
    expect(((src['model'] as Map)['whisper'] as Map)['language'], '');
    expect(identical((out['model'] as Map)['whisper'], (src['model'] as Map)['whisper']), isFalse);

    final sense = {
      'model': {
        'senseVoice': {'model': 'm.onnx', 'language': ''},
        'tokens': 't.txt',
      },
    };
    final senseOut = AiPipeline.withAsrLanguage(sense, 'ja');
    expect(((senseOut['model'] as Map)['senseVoice'] as Map)['language'], 'ja');
  });

  test('自动判断时原样返回，不能把单语模型写死的 language 盖掉', () {
    // whisper-small.en 这类模型在清单里就写着 language=en，
    // 用空串盖掉等于让它去猜语种，而它根本没有别的语种可猜。
    final en = {
      'model': {
        'whisper': {'encoder': 'e.onnx', 'decoder': 'd.onnx', 'task': 'transcribe', 'language': 'en'},
        'tokens': 't.txt',
      },
    };
    final out = AiPipeline.withAsrLanguage(en, '');
    expect(((out['model'] as Map)['whisper'] as Map)['language'], 'en');
  });

  test('语言和 task 叠着用，互不覆盖', () {
    final out = AiPipeline.withWhisperTask(AiPipeline.withAsrLanguage(baseCfg(), 'zh'), 'translate');
    final whisper = (out['model'] as Map)['whisper'] as Map;
    expect(whisper['language'], 'zh');
    expect(whisper['task'], 'translate');
  });

}
