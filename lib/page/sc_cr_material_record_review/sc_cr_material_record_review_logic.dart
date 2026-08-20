import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_pipeline.dart';
import 'package:repeat_flutter/logic/ai/infer_isolate.dart';
import 'package:repeat_flutter/logic/ai/record_commit.dart';
import 'package:repeat_flutter/logic/ai/record_session.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'sc_cr_material_record_review_state.dart';

class ScCrMaterialRecordReviewLogic extends GetxController {
  static const String id = "ScCrMaterialRecordReviewLogic";
  final ScCrMaterialRecordReviewState state = ScCrMaterialRecordReviewState();

  final AudioPlayer _player = AudioPlayer();

  /// 只在真要重跑时才起。复核页多数时候只是看看和改改文字，
  /// 没必要一进来就把几百 MB 模型拉进内存。
  InferIsolate? _infer;
  StreamSubscription<InferResult>? _inferSub;
  Completer<InferResult>? _waiting;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is List && args.length >= 2 && args[0] is Book && args[1] is String) {
      state.book = args[0] as Book;
      state.sessionDir = args[1] as String;
    }
    _load();
  }

  @override
  void onClose() {
    _inferSub?.cancel();
    _infer?.dispose();
    _player.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    state.loading.value = true;
    try {
      final session = await RecordSession.open(state.sessionDir);
      if (session == null) {
        state.error.value = I18nKey.aiReviewEmpty.tr;
        return;
      }
      state.session = session;
      state.segments.assignAll(session.segments);
    } finally {
      state.loading.value = false;
    }
  }

  /// 懒起推理 isolate。返回 false 表示模型不齐，重跑功能用不了（但改文字和提交照常）。
  Future<bool> _ensureInfer() async {
    if (_infer != null) {
      return true;
    }
    try {
      final catalog = await AiCatalog.load();
      final build = await AiPipeline.prepare(catalog);
      if (build == null) {
        final missing = await AiPipeline.missingRole(catalog);
        state.error.value = I18nKey.aiModelMissing.trArgs([missing?.label ?? '']);
        return false;
      }
      _infer = await InferIsolate.start(build);
      _inferSub = _infer!.results.listen((r) {
        // 复核页是一次一段地重跑，用 completer 把异步结果拉回同步的调用点
        if (_waiting != null && !_waiting!.isCompleted) {
          _waiting!.complete(r);
        }
      }, onError: (Object e) {
        if (_waiting != null && !_waiting!.isCompleted) {
          _waiting!.completeError(e);
        }
      });
      return true;
    } catch (e) {
      debugPrint('review infer start failed: $e');
      state.error.value = '$e';
      return false;
    }
  }

  Future<InferResult?> _run(InferJob job) async {
    if (!await _ensureInfer()) {
      return null;
    }
    final completer = Completer<InferResult>();
    _waiting = completer;
    _infer!.submit(job);
    try {
      return await completer.future.timeout(const Duration(minutes: 3));
    } catch (e) {
      debugPrint('review infer job failed: $e');
      state.error.value = '$e';
      return null;
    } finally {
      _waiting = null;
    }
  }

  String _ttsNameOf(RecordSegment seg) => '${seg.index.toString().padLeft(4, '0')}.tts.wav';

  /// 重跑一段。[kind] 决定跑哪几步。
  Future<void> rerun(RecordSegment seg, InferJobKind kind) async {
    final session = state.session;
    if (session == null || state.busy.value) {
      return;
    }
    state.busy.value = true;
    state.workingIndex.value = seg.index;
    try {
      Float32List? samples;
      if (kind != InferJobKind.tts) {
        if (seg.wav.isEmpty) {
          state.error.value = I18nKey.aiReviewNoAudio.tr;
          return;
        }
        samples = await Wav.read(session.pathOf(seg.wav));
        if (samples == null) {
          state.error.value = I18nKey.aiReviewNoAudio.tr;
          return;
        }
      }
      final result = await _run(InferJob(
        index: seg.index,
        kind: kind,
        samples: samples,
        // 合成用的是当前（可能被用户改过的）译文，不是模型原来吐的那份
        text: kind == InferJobKind.tts ? seg.dst : null,
        outWavPath: (kind == InferJobKind.tts || kind == InferJobKind.full)
            ? session.pathOf(_ttsNameOf(seg))
            : null,
      ));
      if (result == null) {
        return;
      }
      if (!result.ok) {
        seg.state = RecordSegmentState.failed;
        state.error.value = result.error ?? '';
      } else {
        if (result.src != null) seg.src = result.src!;
        if (result.dst != null) seg.dst = result.dst!;
        if (result.ttsPath != null) {
          seg.tts = _ttsNameOf(seg);
          seg.ttsMs = result.ttsMs;
        }
        seg.state = RecordSegmentState.done;
      }
      await session.save();
      state.segments.refresh();
    } finally {
      state.busy.value = false;
      state.workingIndex.value = -1;
    }
  }

  /// 把所有没做完的段跑一遍。串行——推理 isolate 本来就是串行的，
  /// 这里并发投递只会让进度显示乱掉。
  Future<void> processAll() async {
    if (state.busy.value) {
      return;
    }
    final todo = state.segments.where((e) => e.state != RecordSegmentState.done).toList();
    for (final seg in todo) {
      await rerun(seg, InferJobKind.full);
    }
  }

  Future<void> play(RecordSegment seg) async {
    final session = state.session;
    if (session == null || seg.tts.isEmpty) {
      Snackbar.show(I18nKey.aiReviewNoAudio.tr);
      return;
    }
    try {
      final path = session.pathOf(seg.tts);
      if (!await File(path).exists()) {
        Snackbar.show(I18nKey.aiReviewNoAudio.tr);
        return;
      }
      await _player.setFilePath(path);
      await _player.seek(Duration.zero);
      // 不 await play()：它要等整段放完才 resolve
      unawaited(_player.play());
    } catch (e) {
      debugPrint('review play failed: $e');
    }
  }

  void editText(RecordSegment seg, {required bool source}) {
    final model = (source ? seg.src : seg.dst).obs;
    MsgBox.strInputWithYesOrNo(
      model,
      source ? I18nKey.aiReviewSrc.tr : I18nKey.aiReviewDst.tr,
      null,
      maxLines: 3,
      yes: () async {
        Get.back();
        final v = model.value.trim();
        if (source) {
          seg.src = v;
        } else {
          seg.dst = v;
        }
        // 手工填过内容的段不该再显示成 failed，否则"全部处理"会把人工修改覆盖掉
        if (seg.src.isNotEmpty || seg.dst.isNotEmpty) {
          seg.state = RecordSegmentState.done;
        }
        await state.session?.save();
        state.segments.refresh();
      },
      no: () => Get.back(),
    );
  }

  void remove(RecordSegment seg) {
    MsgBox.yesOrNo(
      title: I18nKey.aiReviewDelete.tr,
      desc: seg.src.isEmpty ? seg.dst : seg.src,
      yes: () async {
        Get.back();
        await state.session?.removeSegment(seg);
        state.segments.remove(seg);
        state.segments.refresh();
      },
      no: () => Get.back(),
    );
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final session = state.session;
    if (session == null) {
      return;
    }
    // 用的是 onReorderItem 而不是废弃的 onReorder：前者给的 newIndex 已经替
    // "先移除再插入"修正过了，这里绝不能再自己减一，否则往下拖会错一格。
    final seg = state.segments.removeAt(oldIndex);
    state.segments.insert(newIndex, seg);
    // session.segments 是同一批对象，但顺序要跟着改，因为提交是按它的顺序建 verse 的
    session.segments
      ..clear()
      ..addAll(state.segments);
    await session.save();
  }

  Future<void> commit() async {
    final session = state.session;
    if (session == null || state.busy.value) {
      return;
    }
    if (state.segments.every((e) => e.src.trim().isEmpty && e.dst.trim().isEmpty)) {
      Snackbar.show(I18nKey.aiReviewEmpty.tr);
      return;
    }
    state.busy.value = true;
    try {
      final result = await showOverlay<RecordCommitResult>(
        () => RecordCommit.commit(bookId: state.book.id!, session: session),
        I18nKey.aiReviewCommit.tr,
      );
      if (!result.ok) {
        Snackbar.show(result.error == 'empty'
            ? I18nKey.aiReviewEmpty.tr
            : I18nKey.labelDataAnomaly.trArgs([result.error ?? '']));
        return;
      }
      // addChapterWithVerses 内部已经发了 addChapter 事件，素材列表会自己刷新；
      // 这里只负责把用户带回去。
      Nav.scCrMaterial.until();
      Snackbar.show(result.skipped > 0
          ? '${I18nKey.aiReviewCommitted.trArgs(['${result.verseCount}'])} · '
              '${I18nKey.aiReviewSkipped.trArgs(['${result.skipped}'])}'
          : I18nKey.aiReviewCommitted.trArgs(['${result.verseCount}']));
    } finally {
      state.busy.value = false;
    }
  }

  void discard() {
    MsgBox.yesOrNo(
      title: I18nKey.aiReviewDiscard.tr,
      desc: I18nKey.aiRecordDiscardConfirm.tr,
      yes: () async {
        Get.back();
        await state.session?.discard();
        Nav.scCrMaterial.until();
      },
      no: () => Get.back(),
    );
  }
}
