library i18n;

import 'package:get/get.dart';

enum I18nKey {
  appName,
  settings,
  content,
  statistic,
  language,
  theme,
  themeDark,
  themeLight,
  btnDelete,
  btnEdit,
  btnCopy,
  btnDownload,
  ;

  String trArgs([List<String> args = const []]) {
    return name.trArgs(args);
  }
}

extension I18nKeyExtension on I18nKey {
  String get tr {
    return name.tr;
  }
}
