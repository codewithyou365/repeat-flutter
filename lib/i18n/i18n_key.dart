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
  labelDeveloping,
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
  labelExecuting,
  labelResetLearn,
  labelResetLearnDesc,
  labelConfigSettingsForEl,
  labelConfigSettingsForElDesc,
  labelConfigSettingsForRel,
  labelConfigSettingsForRelDesc,
  labelElConfig0000,
  labelElConfig0001,
  labelElConfig0010,
  labelElConfig0011,
  labelElConfig0100,
  labelElConfig0101,
  labelElConfig0110,
  labelElConfig0111,
  labelElConfig1000,
  labelElConfig1001,
  labelElConfig1010,
  labelElConfig1011,
  labelElConfig1100,
  labelElConfig1101,
  labelElConfig1110,
  labelElConfig1111,
  labelFinish,
  labelSavingConfirm,
  labelConfigChange,
  labelResetConfig,
  labelResetConfigDesc,
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
