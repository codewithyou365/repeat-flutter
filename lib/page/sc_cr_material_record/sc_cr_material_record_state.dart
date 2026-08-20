import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
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

  /// 角色 -> 当前生效的模型名，空串表示这个角色还没有可用模型。
  /// 只用于展示：真正生效的选中项在 Kv 里，开录时才读。
  final RxMap<AiRole, String> modelNames = <AiRole, String>{}.obs;

  /// 是否走远程推理（识别/翻译/合成跑在局域网里的电脑上）。只用于展示角标；
  /// VAD 不算在内——它永远跑在手机上。
  final RxBool remote = false.obs;

  /// 服务端当前生效的模型名。开了远程时那三行显示的是它，不是 [modelNames]
  /// ——选哪个模型由服务端决定。空表示还没拉到。
  final RxMap<AiRole, String> remoteModelNames = <AiRole, String>{}.obs;

  /// 服务端探活是否成功。失败时那三行显示"未连接"。
  final RxBool remoteReachable = false.obs;

  /// 当前钉死的识别语言，空串 = 自动判断。跟 modelNames 一样只用于展示。
  final RxString asrLanguage = ''.obs;

  /// 合成音色和这个模型的音色总数。总数 <= 1 时那一行根本不显示。
  final RxInt ttsVoice = 0.obs;
  final RxInt ttsVoices = 1.obs;

  /// 音色名表，下标即 speaker id。空表示模型没给名字，界面退回编号显示。
  final Rx<List<String>> ttsVoiceNames = Rx<List<String>>(const []);

  RecordSession? session;

  /// 展示用的段列表，顺序即 session.segments 的顺序
  final RxList<RecordSegment> segments = <RecordSegment>[].obs;

  final RxInt elapsedMs = 0.obs;

  /// 停止后正在排空推理队列
  final RxBool draining = false.obs;
  final RxString error = ''.obs;

  int get pendingCount => segments.where((e) => e.state == RecordSegmentState.pending).length;
}
