import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

enum RecordSegmentState { pending, done, failed }

enum RecordSessionState { recording, reviewing, committed }

class RecordSegment {
  /// 会话内的序号，同时也是文件名。删掉中间某一段后序号会不连续，这是有意的：
  /// 重编号意味着要改文件名，崩在中间就对不上了。展示顺序看数组顺序，不看这个值。
  final int index;
  String src;
  String dst;

  /// 相对会话目录的文件名，空表示还没有
  String wav;
  String tts;

  /// 合成音频的时长，写 verse 的 end 要用
  int ttsMs;
  RecordSegmentState state;

  RecordSegment({
    required this.index,
    this.src = '',
    this.dst = '',
    this.wav = '',
    this.tts = '',
    this.ttsMs = 0,
    this.state = RecordSegmentState.pending,
  });

  Map<String, dynamic> toJson() => {
        'i': index,
        'src': src,
        'dst': dst,
        'wav': wav,
        'tts': tts,
        'ttsMs': ttsMs,
        'state': state.name,
      };

  static RecordSegment fromJson(Map<String, dynamic> json) {
    return RecordSegment(
      index: (json['i'] as num?)?.toInt() ?? 0,
      src: json['src'] as String? ?? '',
      dst: json['dst'] as String? ?? '',
      wav: json['wav'] as String? ?? '',
      tts: json['tts'] as String? ?? '',
      ttsMs: (json['ttsMs'] as num?)?.toInt() ?? 0,
      // 状态是存进 json 的枚举，读回来不能用裸 byName：
      // 将来加了新状态，旧版本读到会直接抛异常，整个恢复流程白屏。
      state: RecordSegmentState.values.where((e) => e.name == json['state']).firstOrNull ??
          RecordSegmentState.pending,
    );
  }
}

/// 一次录音会话。提交成章节之前，所有东西都在磁盘上，不进数据库。
///
/// 为什么不建表：每行都会 1:1 对应一个本来就必须存在的音频文件，建表等于两份真相，
/// 还要处理两边发散时的回收；而这批数据的整个寿命就到"提交"为止，提交完全删。
/// Floor 买的是查询和 join，这里一次查询都没有。
///
/// 崩溃安全靠两点：VAD 一切出段就先把 wav 落盘再去推理；每次状态变化都
/// 先写 session.json.tmp 再 rename（同一文件系统上 rename 是原子的）。
/// 于是息屏录了半小时被系统杀掉，回来最多丢最后一段的识别结果，音频一段不丢。
class RecordSession {
  static const String jsonName = 'session.json';
  static const String dirName = 'rec';
  static const int version = 1;

  final String dir;
  final int bookId;
  final int createTime;
  String srcLang;
  String dstLang;
  RecordSessionState state;
  final List<RecordSegment> segments;

  RecordSession({
    required this.dir,
    required this.bookId,
    required this.createTime,
    this.srcLang = '',
    this.dstLang = 'en',
    this.state = RecordSessionState.recording,
    List<RecordSegment>? segments,
  }) : segments = segments ?? [];

  String get jsonPath => dir.joinPath(jsonName);

  String pathOf(String name) => dir.joinPath(name);

  /// 下一段用的序号。取已有最大值 +1，而不是 length——删过段之后 length 会撞车。
  int get nextIndex => segments.isEmpty ? 1 : segments.map((e) => e.index).reduce((a, b) => a > b ? a : b) + 1;

  int get pendingCount => segments.where((e) => e.state == RecordSegmentState.pending).length;

  static Future<String> _rootDir() async {
    final content = await DocPath.getContentPath();
    // 放课堂目录下的 rec/，不是 f/：f/ 是分享 zip 的载荷，
    // 会话里的原始录音是中间产物，绝不该跟着课堂被分享出去。
    return content.joinPath(DocPath.getClassroomRelativePath(Classroom.curr)).joinPath(dirName);
  }

  static Future<RecordSession> create(int bookId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dir = (await _rootDir()).joinPath('$now');
    await Folder.ensureExists(dir);
    final s = RecordSession(dir: dir, bookId: bookId, createTime: now);
    await s.save();
    return s;
  }

  static Future<RecordSession?> open(String dir) async {
    try {
      final f = File(dir.joinPath(jsonName));
      if (!await f.exists()) {
        return null;
      }
      final json = jsonDecode(await f.readAsString());
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return RecordSession(
        dir: dir,
        bookId: (json['bookId'] as num?)?.toInt() ?? 0,
        createTime: (json['createTime'] as num?)?.toInt() ?? 0,
        srcLang: json['srcLang'] as String? ?? '',
        dstLang: json['dstLang'] as String? ?? 'en',
        state: RecordSessionState.values.where((e) => e.name == json['state']).firstOrNull ??
            RecordSessionState.recording,
        segments: ((json['segments'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(RecordSegment.fromJson)
            .toList(),
      );
    } catch (e) {
      debugPrint('RecordSession.open($dir) failed: $e');
      return null;
    }
  }

  /// 还没提交完的会话。息屏录到一半被系统杀掉，靠这个把人领回复核页。
  static Future<List<RecordSession>> findUnfinished() async {
    final out = <RecordSession>[];
    try {
      final root = Directory(await _rootDir());
      if (!await root.exists()) {
        return out;
      }
      for (final e in await root.list(followLinks: false).toList()) {
        if (e is! Directory) continue;
        final s = await open(e.path);
        if (s == null) continue;
        if (s.state == RecordSessionState.committed || s.segments.isEmpty) {
          // 已提交或一段都没录的，直接清掉，别每次都来问用户
          await Folder.delete(e.path);
          continue;
        }
        out.add(s);
      }
    } catch (e) {
      debugPrint('RecordSession.findUnfinished failed: $e');
    }
    out.sort((a, b) => b.createTime.compareTo(a.createTime));
    return out;
  }

  Map<String, dynamic> toJson() => {
        'v': version,
        'bookId': bookId,
        'createTime': createTime,
        'srcLang': srcLang,
        'dstLang': dstLang,
        'state': state.name,
        'segments': segments.map((e) => e.toJson()).toList(),
      };

  /// 先写 .tmp 再 rename。直接覆盖写的话，正好写到一半掉电就得到一个坏 json，
  /// 那等于把整场录音的索引丢了（音频文件还在，但没人知道它们的顺序和文本）。
  Future<void> save() async {
    final tmp = File('$jsonPath.tmp');
    await tmp.writeAsString(jsonEncode(toJson()), flush: true);
    await tmp.rename(jsonPath);
  }

  /// 落一段新录音。**先落盘，再入队推理**——音频是唯一不可再生的东西。
  Future<RecordSegment> addSegment(Float32List samples) async {
    final seg = RecordSegment(index: nextIndex);
    seg.wav = '${seg.index.toString().padLeft(4, '0')}.wav';
    await Wav.write(pathOf(seg.wav), samples);
    segments.add(seg);
    await save();
    return seg;
  }

  Future<void> removeSegment(RecordSegment seg) async {
    segments.remove(seg);
    for (final name in [seg.wav, seg.tts]) {
      if (name.isEmpty) continue;
      try {
        final f = File(pathOf(name));
        if (await f.exists()) await f.delete();
      } catch (e) {
        debugPrint('RecordSession.removeSegment delete $name failed: $e');
      }
    }
    await save();
  }

  Future<void> discard() async {
    await Folder.delete(dir);
  }
}
