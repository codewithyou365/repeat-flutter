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
