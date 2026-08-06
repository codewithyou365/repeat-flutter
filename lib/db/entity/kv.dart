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
  materialSharePort,
  expandServiceUrl,
  adminId,
  adminEnable,
  webviewHandlePos,
  tipServerPort,
  bluetoothStopLeadMs,
  // K 是按 name 存的（见 KConverter），只能往后加，不能改名或删
  classroomSharePort,
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
