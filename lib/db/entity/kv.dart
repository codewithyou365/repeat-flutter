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

  /// 翻译引擎 id，见 TranslateEngine.id。默认 whisper。
  aiTranslateEngine,
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
