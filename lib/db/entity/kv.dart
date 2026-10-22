// entity/kv.dart

import 'package:floor/floor.dart';

enum K {
  settingsI18n,
  settingsTheme,
  exportUrl,
  importUrl,
  allowRegisterNumber,
  bookAdvancedEditorVimMode,
  bookAdvancedEditorRelativeNumbers,
  closeEyesDirect,
  generateSslTime,
  credential,
  credentialExpireTime,
  gamePassword,
  gamePasswordCreateTime,
  lastVerseId,
  mediaSharePort,
  gameServerPort,
  bookEditorPort,

  /// 书本分享已经删掉，这个值只剩老库里可能残留的行。KConverter 是按 name 反解的，
  /// 删掉枚举值会让读到这些行的查询直接抛异常，所以留着（clearAtAppStart 会清掉它）。
  materialSharePort,
  expandServiceUrl,
  adminId,
  adminEnable,
  webviewHandlePos,
  tipServerPort,
  bluetoothStopLeadMs,
  // K 是按 name 存的（见 KConverter），只能往后加，不能改名或删
  classroomSharePort,

  /// AI 模型清单的远程覆盖地址。空则只用内置的 assets/ai/catalog.json。
  aiCatalogUrl,

  /// 各角色当前选中的模型 id。模型是全设备共享的资源（一份几百 MB），
  /// 所以放 K 而不是 CrK——删掉一个课堂不该把下载好的模型也孤立掉。
  aiVadModelId,
  aiAsrModelId,
  aiMtModelId,
  aiTtsModelId,

  /// 识别语言，见 AiLang。空串 = 自动判断语种。
  /// 跟模型选中项一样放 K：说话的是同一个人，换个课堂不会突然改说别的语言。
  aiAsrLanguage,

  /// 翻译引擎 id，见 TranslateEngine.id。默认 whisper。
  aiTranslateEngine,

  /// 模型下载源，见 AiDownloadSource。清单里一律存官方地址，下载时才改写。
  aiDownloadSource,
  aiCustomHfHost,
  aiCustomGhPrefix,

  /// 远程推理服务地址，形如 http://192.168.1.2:8767。服务端见 server/ai。
  aiRemoteUrl,

  /// 是否启用远程推理。关掉时地址保留，方便来回切。
  aiRemoteEnabled,

  /// 跟读打分服务地址，形如 http://192.168.1.2:8766。服务端见 server/shadow。
  ///
  /// 和 aiRemoteUrl 分开存：那是 8767 的翻译/识别服务，这是 8766 的发音评测，
  /// 两个独立进程，完全可能只开其中一个。
  shadowRemoteUrl,

  /// 是否启用跟读打分。关掉时地址保留。
  shadowRemoteEnabled,

  /// 小节里的网页内容能不能联网（引用 CDN 上的库、在线的模型和贴图）。
  ///
  /// **默认开**，所以只有显式存 '0' 才算关。关掉之后网页只能用自己包里带的文件，
  /// 由 ContentWebServer 发一条 CSP 头钉死，见 [ContentWebServer]。
  ///
  /// 放 K 不放 CrK：这是使用者对"我这台设备上的内容允不允许出网"的取舍，
  /// 跟在哪个课堂无关。
  contentWebNetwork,
}

@Entity(primaryKeys: ['k'])
class Kv {
  final K k;
  final String value;

  Kv(
    this.k,
    this.value,
  );
}
