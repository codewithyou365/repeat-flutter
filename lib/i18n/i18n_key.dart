library i18n;

import 'package:get/get.dart';

enum I18nKey {
  appName,
  settings,
  content,
  statistic,
  statisticLearn,
  statisticReview,
  language,
  theme,
  themeDark,
  themeLight,
  labelUrl,
  labelAddContentIndex,
  labelEditContentIndex,
  labelDeleteContentIndex,
  labelDownloadContent,
  labelScheduleContent,
  labelNoLearningContent,
  labelResetLearningContent,
  labelTips,
  labelNoContent,
  btnCancel,
  btnOk,
  btnDelete,
  btnEdit,
  btnAdd,
  btnCopy,
  btnDownload,
  btnSchedule,
  btnLearn,
  btnReview,
  btnShow,
  btnUnknown,
  btnKnow,
  btnError,
  btnNext,
  btnFinish,
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
