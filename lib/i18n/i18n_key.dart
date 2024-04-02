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
  labelUrl,
  labelAddContentIndex,
  labelEditContentIndex,
  labelDeleteContentIndex,
  labelDownloadContent,
  btnCancel,
  btnOk,
  btnDelete,
  btnEdit,
  btnAdd,
  btnCopy,
  btnDownload,
  btnReview,
  btnRepeat,
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
