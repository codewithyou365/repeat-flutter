library i18n;

import 'i18n_key.dart';

class Config {
  final Map<String, String> data = {};

  Config(Map<String, String>? defaultData) {
    if (defaultData != null) {
      data.addAll(defaultData);
    }
  }

  void put(I18nKey key, String value) {
    data[key.name] = value;
  }
}
