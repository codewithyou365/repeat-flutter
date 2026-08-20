import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/ai/record_session.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

class RecordCommitResult {
  final bool ok;

  /// 真正写进章节的段数
  final int verseCount;

  /// 被跳过的段数（原文和译文都是空的）
  final int skipped;
  final String? error;

  const RecordCommitResult({
    required this.ok,
    this.verseCount = 0,
    this.skipped = 0,
    this.error,
  });
}

/// 把一次录音会话提交成一个章节。
class RecordCommit {
  /// 拼一条 verse 的内容。
  ///
  /// 合成音频挂在 'a' 这个字段块上（块内的 mediaHash + showType），**不动整节的 's'/'m'**：
  /// 这个模式下没有整章共用媒体，每个字段块自带文件。设 'm' 反而会造出一个指不到东西的
  /// 整节引用。这跟 ChapterImportHelp（整章共用一个音视频）的做法不同，是有意的。
  ///
  /// q 侧只有文字：用户选的是完全不存原声。
  @visibleForTesting
  static Map<String, dynamic> buildVerse({
    required String src,
    required String dst,
    DownloadContent? tts,
    int ttsMs = 0,
  }) {
    final m = <String, dynamic>{};
    if (src.isNotEmpty) {
      VerseField.setStr(m, 'q', VerseField.text, src);
    }
    if (dst.isNotEmpty) {
      VerseField.setStr(m, 'a', VerseField.text, dst);
    }
    if (tts != null && dst.isNotEmpty) {
      VerseField.setMedia(verse: m, acronym: 'a', d: tts);
      VerseField.setStr(m, 'a', VerseField.showType, RepeatViewEnum.audio.name);
      VerseField.setStr(m, 'a', VerseField.start, "00:00:00,000");
      VerseField.setStr(m, 'a', VerseField.end, Time.convertMsToString(ttsMs));
    }
    return m;
  }

  /// 提交。成功后会话目录（含所有原始录音）整个删掉。
  ///
  /// 用户选的是"完全不存原声"，所以 q 侧只有文字，原始录音只是中间产物；
  /// 挂到 a 上的是 AI 合成的译文音频。
  static Future<RecordCommitResult> commit({
    required int bookId,
    required RecordSession session,
  }) async {
    try {
      final verseContents = <String>[];
      var skipped = 0;

      for (final seg in session.segments) {
        final src = seg.src.trim();
        final dst = seg.dst.trim();
        if (src.isEmpty && dst.isEmpty) {
          // 识别失败又没人工补过的段，写进去只会是一条空白学习材料
          skipped++;
          continue;
        }

        DownloadContent? dc;
        if (seg.tts.isNotEmpty && dst.isNotEmpty) {
          final wav = File(session.pathOf(seg.tts));
          if (await wav.exists()) {
            // copy 而不是 move：万一后面某一段挂了，会话目录还得完整留着让用户重试。
            // f/ 里多几个没人引用的文件是可回收垃圾，会话被毁掉才是不可逆的。
            dc = await DocHelp.moveToDocDir(wav.path, true);
          }
        }
        verseContents.add(jsonEncode(buildVerse(src: src, dst: dst, tts: dc, ttsMs: seg.ttsMs)));
      }

      if (verseContents.isEmpty) {
        return RecordCommitResult(ok: false, skipped: skipped, error: 'empty');
      }

      final chapterIndex = await Db().db.chapterDao.count(bookId) ?? 0;
      final ok = await Db().db.chapterDao.addChapterWithVerses(
        bookId: bookId,
        chapterIndex: chapterIndex,
        // 章节自己没有名字（身份就是下标），也没有整章媒体，所以是空的
        chapterContent: "{}",
        verseContents: verseContents,
      );
      if (!ok) {
        return const RecordCommitResult(ok: false, error: 'addChapterWithVerses failed');
      }

      // 建章成功才删会话。原始录音到这一步就没用了（用户选的是不存原声）。
      session.state = RecordSessionState.committed;
      await session.save();
      await session.discard();

      return RecordCommitResult(ok: true, verseCount: verseContents.length, skipped: skipped);
    } catch (e) {
      debugPrint('RecordCommit.commit failed: $e');
      return RecordCommitResult(ok: false, error: '$e');
    }
  }
}
