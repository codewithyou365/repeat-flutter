import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/ai/ai_download_source.dart';

void main() {
  const cn = AiUrlRewriter(
    hfHost: AiDownloadSourceHelp.cnHfHost,
    ghPrefix: AiDownloadSourceHelp.cnGhPrefix,
  );
  const official = AiUrlRewriter(hfHost: '', ghPrefix: '');

  test('官方源原样不动', () {
    const u = 'https://huggingface.co/csukuangfj/x/resolve/main/a.onnx';
    expect(official(u), u);
    expect(official.isIdentity, isTrue);
  });

  test('HuggingFace 换主机，路径一个字符都不能变', () {
    expect(
      cn('https://huggingface.co/csukuangfj/vits-melo-tts-zh_en/resolve/main/dict/jieba.dict.utf8'),
      'https://hf-mirror.com/csukuangfj/vits-melo-tts-zh_en/resolve/main/dict/jieba.dict.utf8',
    );
  });

  test('GitHub 是加前缀，不是换主机', () {
    const u = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx';
    expect(cn(u), 'https://ghfast.top/$u');
  });

  test('已经带过前缀的不再套一层', () {
    const u = 'https://ghfast.top/https://github.com/k2-fsa/sherpa-onnx/releases/download/x.onnx';
    expect(cn(u), u);
  });

  test('自定义前缀没带结尾斜杠也能拼对', () {
    const r = AiUrlRewriter(hfHost: 'my.mirror', ghPrefix: 'https://my.gh');
    expect(r('https://huggingface.co/a/b'), 'https://my.mirror/a/b');
    expect(r('https://github.com/a/b'), 'https://my.gh/https://github.com/a/b');
  });

  test('只配了一边时，另一边不受影响', () {
    const onlyHf = AiUrlRewriter(hfHost: 'my.mirror', ghPrefix: '');
    const gh = 'https://github.com/a/b';
    expect(onlyHf(gh), gh);
    const onlyGh = AiUrlRewriter(hfHost: '', ghPrefix: 'https://p/');
    const hf = 'https://huggingface.co/a/b';
    expect(onlyGh(hf), hf);
  });

  test('不相干的地址不动', () {
    const u = 'https://example.com/model.onnx';
    expect(cn(u), u);
  });

  test('主机名只在带协议时匹配，避免误伤路径里出现的同名字符串', () {
    // 路径里带 huggingface.co 的自建地址不该被改写
    const u = 'https://my.host/mirror/huggingface.co/a/b';
    expect(cn(u), u);
  });
}
