library i18n;

import 'package:get/get.dart';

enum I18nKey {
  appName,
  settings,
  content,
  contentShare,
  mediaImportTemplate,
  statistic,
  statisticLearn,
  statisticReview,
  language,
  theme,
  data,
  themeDark,
  themeLight,
  labelDeveloping,
  labelTitle,
  labelSelectClassroom,
  labelDeleteClassroom,
  labelDeleteClassroomAll,
  labelClassroomName,
  labelClassroomNameEmpty,
  labelClassroomNameError,
  labelClassroomNameDuplicated,
  labelContentName,
  labelContentNameEmpty,
  labelContentNameError,
  labelContentNameDuplicated,
  labelDelete,
  labelRemoteUrl,
  labelOriginalAddress,
  labelLanAddress,
  labelDownloadFirstBeforeSharing,
  labelDownloadFirstBeforeSaving,
  labelAddContent,
  labelEditContentIndex,
  labelDeleteContent,
  labelDownloadContent,
  labelScheduleContent,
  labelNoLearningContent,
  labelResetLearningContent,
  labelTips,
  labelReviewThisCount,
  labelLearnCount,
  labelReviewCount,
  labelFullCustomCount,
  labelNoContent,
  labelJsonErrorSaveFailed,
  labelImportFailed,
  labelImportSuccess,
  labelImportMojo,
  labelImportMojoTips,
  labelImportCanceled,
  labelImporting,
  labelExporting,
  labelExecuting,
  labelSaving,
  labelSelectDirectoryToSave,
  labelFileSaved,
  labelSaveSuccess,
  labelDirectoryPermissionDenied,
  labelSaved,
  labelSaveCancel,
  labelStoragePermissionDenied,
  labelAdjustLearnProgress,
  labelAdjustLearnProgressDesc,
  labelPleaseInputUnSignNumber,
  labelReset,
  labelResetAllDesc,
  labelResetLearnDesc,
  labelResetReviewDesc,
  labelResetFullCustomDesc,
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
  labelRelConfig0,
  labelRelConfig1,
  labelFullCustomConfig,
  labelElRandom,
  labelElToLevel,
  labelElLevel,
  labelElLearnCount,
  labelRelBefore,
  labelRelFrom,
  labelLearnCountPerGroup,
  labelFinish,
  labelALL,
  labelSavingConfirm,
  labelConfigChange,
  labelResetConfig,
  labelDetailConfig,
  labelDetail,
  labelCopyConfig,
  labelDeleteConfig,
  labelCopyText,
  labelResetPassword,
  labelResetConfigDesc,
  labelOnTapError,
  labelSetMaskTips,
  labelQrCodeContentCopiedToClipboard,
  labelCopiedToClipboard,
  labelShouldLinkToTheContentBeAdded,
  labelTooMuchData,
  labelDataDuplication,
  labelDataAnomaly,
  labelDataAnomalyWithArg,
  labelRemoteImport,
  labelLocalZipImport,
  labelLocalMediaImport,
  labelLocalImportCancel,
  labelSegmentRemoved,
  labelDocNotBeDownloaded,
  labelDocCantBeFound,
  labelInputPathError,
  labelScheduleCount,
  labelFrom,
  labelLesson,
  labelSegment,
  labelIgnorePunctuation,
  labelMatchType,
  labelSkipCharacter,
  labelEditInGame,
  labelGameId,
  labelOnlineUserNumber,
  labelAllowRegisterNumber,
  labelGameStartNeedRecallStop,
  labelQuestion,
  labelAnswer,
  labelQuestionAndAnswer,
  labelCopyMode,
  labelWord,
  labelSingle,
  labelAll,
  labelSetLevel,
  labelSetNextLearnDate,
  btnStart,
  btnStop,
  btnAddSchedule,
  btnConfigSettings,
  btnSet,
  btnUse,
  btnSetHead,
  btnSetTail,
  btnExtendTail,
  btnResetTail,
  btnOther,
  btnCut,
  btnDeleteCurr,
  btnCancel,
  btnOk,
  btnDelete,
  btnShare,
  btnEdit,
  btnGameMode,
  btnConcentration,
  btnAdd,
  btnReset,
  btnCopy,
  btnDownload,
  btnSchedule,
  btnLearn,
  btnBrowse,
  btnExamine,
  btnReview,
  btnFullCustom,
  btnRepeat,
  btnShow,
  btnTips,
  btnUnknown,
  btnKnow,
  btnError,
  btnNext,
  btnPrevious,
  btnFinish,
  btnExport,
  btnImport,
  btnSave,
  btnClose,
  btnCheck,
  ;

  String trArgs([List<String> args = const []]) {
    return name.trArgs(args);
  }

  String trParams([List<String> args = const []]) {
    Map<String, String> params = {};
    for (int i = 0; i < args.length; i++) {
      params['$i'] = args[i];
    }
    return name.trParams(params);
  }
}

extension I18nKeyExtension on I18nKey {
  String get tr {
    return name.tr;
  }
}
