import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/logic/ai/record_session.dart';

/// 息屏方式。默认黑屏——它绕开所有 Android 后台麦克风限制，全版本全 ROM 都稳。
enum RecordScreenMode {
  /// App 保持前台可见，整屏纯黑 + 窗口亮度调到 0
  black,

  /// 真息屏：按电源键关屏或切后台照样录，靠 microphone 类型的前台服务撑着
  off,
}

class ScCrMaterialRecordState {
  late Book book;

  final RxBool starting = false.obs;
  final RxBool recording = false.obs;

  /// 黑屏遮罩是否盖着。只在 [RecordScreenMode.black] 下有意义。
  final RxBool blacked = false.obs;
  final Rx<RecordScreenMode> screenMode = RecordScreenMode.black.obs;

  /// 自动播放合成的译文。息屏时这是唯一能确认"它听对没有"的手段。
  final RxBool autoPlay = true.obs;

  RecordSession? session;

  /// 展示用的段列表，顺序即 session.segments 的顺序
  final RxList<RecordSegment> segments = <RecordSegment>[].obs;

  final RxInt elapsedMs = 0.obs;

  /// 停止后正在排空推理队列
  final RxBool draining = false.obs;
  final RxString error = ''.obs;

  int get pendingCount => segments.where((e) => e.state == RecordSegmentState.pending).length;
}
