import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/ai/record_commit.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

void main() {
  const hash = 'aabbccddeeff00112233445566778899aabbccdd';

  test('完整的一段：q 只有文字，a 带文字和合成音频', () {
    final m = RecordCommit.buildVerse(
      src: '今天天气很好',
      dst: 'The weather is nice today.',
      tts: DownloadContent(url: '.wav', hash: hash),
      ttsMs: 2480,
    );

    expect(VerseField.getStr(m, 'q', VerseField.text), '今天天气很好');
    expect(VerseField.getStr(m, 'a', VerseField.text), 'The weather is nice today.');
    expect(VerseField.getStr(m, 'a', VerseField.mediaHash), hash);
    expect(VerseField.getStr(m, 'a', VerseField.showType), 'audio');
    expect(VerseField.getStr(m, 'a', VerseField.start), '00:00:00,000');
    expect(VerseField.getStr(m, 'a', VerseField.end), '00:00:02,480');

    // 文件对象登记进这一节自己的 'd'
    final d = DownloadContent.toList(m['d']);
    expect(d, isNotNull);
    expect(d!.length, 1);
    expect(d.first.hash, hash);
  });

  test('用户选了不存原声：q 侧绝不能有 mediaHash', () {
    final m = RecordCommit.buildVerse(
      src: '你好',
      dst: 'Hello',
      tts: DownloadContent(url: '.wav', hash: hash),
      ttsMs: 800,
    );
    expect(VerseField.getStr(m, 'q', VerseField.mediaHash), isNull);
    expect(VerseField.getStr(m, 'q', VerseField.showType), isNull);
  });

  test('不设整节媒体 m 和整节 showType s', () {
    // 这个模式下没有整章共用媒体，每个字段块自带文件。
    // 设了 'm' 会造出一个指不到东西的整节引用，整章都会播不出来。
    final m = RecordCommit.buildVerse(
      src: '你好',
      dst: 'Hello',
      tts: DownloadContent(url: '.wav', hash: hash),
      ttsMs: 800,
    );
    expect(m.containsKey(VerseField.sectionMediaHash), isFalse);
    expect(m.containsKey('s'), isFalse);
  });

  test('没有合成音频时，a 只有文字，不留半截的音频字段', () {
    final m = RecordCommit.buildVerse(src: '你好', dst: 'Hello');
    expect(VerseField.getStr(m, 'a', VerseField.text), 'Hello');
    expect(VerseField.getStr(m, 'a', VerseField.mediaHash), isNull);
    expect(VerseField.getStr(m, 'a', VerseField.showType), isNull);
    expect(VerseField.getStr(m, 'a', VerseField.end), isNull);
    expect(m['d'], isNull);
  });

  test('译文为空时不挂音频，哪怕传了 DownloadContent', () {
    // 译文空还挂着音频，等于一条没字幕的声音，学不了
    final m = RecordCommit.buildVerse(
      src: '你好',
      dst: '',
      tts: DownloadContent(url: '.wav', hash: hash),
      ttsMs: 800,
    );
    expect(VerseField.getStr(m, 'a', VerseField.mediaHash), isNull);
    expect(m['d'], isNull);
  });

  test('只有原文也能成一条（识别到了但翻译失败）', () {
    final m = RecordCommit.buildVerse(src: '你好', dst: '');
    expect(VerseField.getStr(m, 'q', VerseField.text), '你好');
    expect(m.containsKey('a'), isFalse);
  });

  test('时长换算：整秒与带毫秒', () {
    DownloadContent d() => DownloadContent(url: '.wav', hash: hash);
    expect(
      VerseField.getStr(
          RecordCommit.buildVerse(src: 'a', dst: 'b', tts: d(), ttsMs: 1000), 'a', VerseField.end),
      '00:00:01,000',
    );
    expect(
      VerseField.getStr(
          RecordCommit.buildVerse(src: 'a', dst: 'b', tts: d(), ttsMs: 61234), 'a', VerseField.end),
      '00:01:01,234',
    );
  });
}
