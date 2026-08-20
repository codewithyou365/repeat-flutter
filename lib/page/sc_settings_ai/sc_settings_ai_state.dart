import 'package:get/get.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_download_source.dart';

class ScSettingsAiState {
  final RxBool loading = true.obs;

  AiCatalog catalog = AiCatalog.empty;

  /// modelId -> 是否装好了（.ok 存在）
  final RxMap<String, bool> installed = <String, bool>{}.obs;

  /// 角色 -> 当前实际生效的 modelId。空字符串表示这个角色还没有可用模型。
  final RxMap<AiRole, String> selected = <AiRole, String>{}.obs;

  /// m/ 目录总占用字节数
  final RxInt diskUsage = 0.obs;

  final RxString catalogUrl = ''.obs;
  final Rx<AiDownloadSource> downloadSource = AiDownloadSource.official.obs;

  // ------- 远程推理（服务端见仓库 server/ai）
  final RxBool remoteEnabled = false.obs;
  final RxString remoteUrl = ''.obs;

  /// 测试连接/上传的结果文案。成功和失败都往这儿写，[remoteError] 决定标不标红。
  final RxString remoteStatus = ''.obs;
  final RxBool remoteError = false.obs;
  final RxBool remoteTesting = false.obs;

  /// 上传进度。[uploadingId] 非空时顶部进度条显示的是上传而不是下载。
  final RxString uploadingId = ''.obs;

  // ------- 安装进度。同一时刻只可能有一个模型在装（下载器要求严格串行）
  final RxString installingId = ''.obs;
  final RxInt fileIndex = 0.obs;
  final RxInt fileTotal = 0.obs;
  final RxDouble fileProgress = 0.0.obs;

  /// 整套预设安装时，当前是第几个模型
  final RxString presetName = ''.obs;
  final RxInt presetIndex = 0.obs;
  final RxInt presetTotal = 0.obs;

  bool cancelRequested = false;
}
