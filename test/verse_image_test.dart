import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

/// contents 一律按 verse -> chapter -> book 的顺序传，跟 Helper.fieldLevels 一致。
List<Map<String, dynamic>?> levels({
  Map<String, dynamic>? verse,
  Map<String, dynamic>? chapter,
  Map<String, dynamic>? book,
}) {
  return [verse, chapter, book];
}

DownloadContent d(String hash, [String ext = 'jpg']) {
  return DownloadContent(url: 'http://x/y.$ext', hash: hash);
}

void main() {
  group('配图的就近覆盖', () {
    test('单张写成字符串也认', () {
      final v = {
        'q': {'imageHash': 'h1'}
      };
      expect(VerseField.fieldImageHashes(levels(verse: v), 'q'), ['h1']);
      expect(VerseField.sectionImageHashes(levels(verse: {'g': 'hs'})), ['hs']);
    });

    test('verse 有就用 verse 的，不跟上层合并', () {
      final v = {
        'q': {'imageHash': ['h1']}
      };
      final c = {
        'q': {'imageHash': ['h2', 'h3']}
      };
      expect(VerseField.fieldImageHashes(levels(verse: v, chapter: c), 'q'), ['h1']);
    });

    test('verse 没写就继承 chapter，chapter 没写继承 book', () {
      final c = {
        'q': {'imageHash': ['h2']}
      };
      final b = {
        'q': {'imageHash': ['h9']}
      };
      expect(VerseField.fieldImageHashes(levels(verse: {}, chapter: c, book: b), 'q'), ['h2']);
      expect(VerseField.fieldImageHashes(levels(verse: {}, book: b), 'q'), ['h9']);
    });

    test('写成空数组就是这一层明确不配图，不能再往上找', () {
      final v = {
        'q': {'imageHash': <String>[]}
      };
      final c = {
        'q': {'imageHash': ['h2']}
      };
      expect(VerseField.fieldImageHashes(levels(verse: v, chapter: c), 'q'), isEmpty);
      expect(VerseField.sectionImageHashes(levels(verse: {'g': <String>[]}, chapter: {'g': ['hs']})), isEmpty);
    });

    test('整节配图同样就近覆盖', () {
      expect(
        VerseField.sectionImageHashes(levels(verse: {}, chapter: {'g': ['hc']}, book: {'g': ['hb']})),
        ['hc'],
      );
    });

    test('declared 认的是键在不在，空数组也算写了', () {
      expect(VerseField.fieldImageDeclared(levels(chapter: {'q': {'imageHash': <String>[]}}), 'q'), isTrue);
      expect(VerseField.fieldImageDeclared(levels(chapter: {'q': {'text': 'x'}}), 'q'), isFalse);
      expect(VerseField.sectionImageDeclared(levels(book: {'g': <String>[]})), isTrue);
      expect(VerseField.sectionImageDeclared(levels(book: {'m': 'x'})), isFalse);
    });
  });

  group('配图文件对象的解析', () {
    test('跨层在 d 里找，找不到的直接跳过', () {
      final v = {
        'd': [d('h1').toJson()],
      };
      final c = {
        'd': [d('h2').toJson()],
      };
      final got = VerseField.resolveImages(levels(verse: v, chapter: c), ['h1', 'missing', 'h2']);
      expect(got.map((e) => e.hash), ['h1', 'h2']);
    });
  });

  group('配图不能碰整节媒体', () {
    test('加配图只往 d 末尾追加，不顶掉没有 m 的老内容的整节媒体', () {
      final audio = d('audio1', 'mp3');
      final verse = <String, dynamic>{
        'd': [audio.toJson()],
      };
      // 没有 'm'：整节媒体按 'd' 第一项算（findSectionDownload 的回落）。
      expect(VerseField.findSectionDownload(levels(verse: verse))!.hash, 'audio1');

      VerseField.addDownload(verse, d('img1'));
      VerseField.setSectionImages(verse, ['img1']);

      expect(VerseField.findSectionDownload(levels(verse: verse))!.hash, 'audio1');
      expect(VerseField.sectionImageHashes(levels(verse: verse)), ['img1']);
    });

    test('配图写的是 imageHash / g，跟 mediaHash / m 各走各的', () {
      final verse = <String, dynamic>{};
      VerseField.setFieldImages(verse, 'a', ['img1']);
      VerseField.setSectionImages(verse, ['img2']);
      expect(VerseField.getStr(verse, 'a', VerseField.mediaHash), isNull);
      expect(verse[VerseField.sectionMediaHash], isNull);
      expect(verse['a'][VerseField.imageHash], ['img1']);
      expect(verse[VerseField.sectionImageHash], ['img2']);
    });
  });

  group('写回', () {
    test('setFieldImages 会就地建出字段块', () {
      final verse = <String, dynamic>{};
      VerseField.setFieldImages(verse, 'q', ['h1', 'h2']);
      expect(VerseField.fieldImageHashes(levels(verse: verse), 'q'), ['h1', 'h2']);
    });

    test('删掉 imageHash 这个键才是把继承权交还给上层', () {
      final verse = <String, dynamic>{
        'q': {'imageHash': <String>[]}
      };
      final chapter = {
        'q': {'imageHash': ['hc']}
      };
      expect(VerseField.fieldImageHashes(levels(verse: verse, chapter: chapter), 'q'), isEmpty);
      VerseField.remove(verse, 'q', [VerseField.imageHash]);
      expect(VerseField.fieldImageHashes(levels(verse: verse, chapter: chapter), 'q'), ['hc']);
    });
  });
}
