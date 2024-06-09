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
  data,
  themeDark,
  themeLight,
  labelSelectClassroom,
  labelDeleteClassroom,
  labelClassroomName,
  labelClassroomNameEmpty,
  labelClassroomNameError,
  labelClassroomNameDuplicated,
  labelDelete,
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
  labelImportFailed,
  labelImportSuccess,
  labelImportMojo,
  labelImportMojoTips,
  labelImportCanceled,
  labelImporting,
  labelExporting,
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
  btnRepeat,
  btnShow,
  btnTips,
  btnUnknown,
  btnKnow,
  btnError,
  btnNext,
  btnFinish,
  btnExport,
  btnImport,
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
