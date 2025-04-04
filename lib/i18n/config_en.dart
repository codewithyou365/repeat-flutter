library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigEn extends Config {
  ConfigEn({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "Repeat");
    put(I18nKey.settings, "Settings");
    put(I18nKey.content, "Content");
    put(I18nKey.contentShare, "Content Share");
    put(I18nKey.mediaImportTemplate, "Media Import Template");
    put(I18nKey.statistic, "Stats");
    put(I18nKey.statisticLearn, "Stats-Learn");
    put(I18nKey.statisticReview, "Stats-Review");
    put(I18nKey.statisticDetail, "Stats-Detail");
    put(I18nKey.language, "Language");
    put(I18nKey.theme, "Theme");
    put(I18nKey.data, "Data");
    put(I18nKey.themeDark, "Dart");
    put(I18nKey.themeLight, "Light");
    put(I18nKey.labelDeveloping, "Developing");
    put(I18nKey.labelTitle, "Title");
    put(I18nKey.labelSelectClassroom, "Select Classroom");
    put(I18nKey.labelDeleteClassroom, "Please confirm to delete \n this classroom : %s");
    put(I18nKey.labelDeleteClassroomAll, "Meanwhile, delete the study records.");
    put(I18nKey.labelClassroomName, "Classroom Name");
    put(I18nKey.labelClassroomNameEmpty, "The classroom name cannot be empty");
    put(I18nKey.labelClassroomNameError, "The classroom name should be 3 letters or less and consist of alphanumeric characters in uppercase.");
    put(I18nKey.labelClassroomNameDuplicated, "The classroom name is duplicated.");
    put(I18nKey.labelContentName, "Content Name");
    put(I18nKey.labelContentNameEmpty, "The content name cannot be empty");
    put(I18nKey.labelContentNameError, "The content name should be 3 letters or less and consist of alphanumeric characters in uppercase.");
    put(I18nKey.labelContentNameDuplicated, "The content name is duplicated.");
    put(I18nKey.labelDelete, "Delete");
    put(I18nKey.labelRemoteUrl, "Remote URL");
    put(I18nKey.labelOriginalAddress, "Original address");
    put(I18nKey.labelLanAddress, "LAN address");
    put(I18nKey.labelDownloadFirstBeforeSharing, "Please download first before sharing.");
    put(I18nKey.labelDownloadFirstBeforeSaving, "Please download first before saving.");
    put(I18nKey.labelAddContent, "Add content");
    put(I18nKey.labelDeleteContent, "Please confirm to delete content: %s");
    put(I18nKey.labelDeleteSegment, "Please confirm to delete the segment");
    put(I18nKey.labelDownloadContent, "Download content");
    put(I18nKey.labelScheduleContent, "Add learning task with %s segments.");
    put(I18nKey.labelNoLearningContent, "There is no learning content available.");
    put(I18nKey.labelResetLearningContent, "The learning content will be reset in %s");
    put(I18nKey.labelTips, "Tips");
    put(I18nKey.labelReviewThisCount, "Review These Segments Count");
    put(I18nKey.labelLearnCount, "Learn Count");
    put(I18nKey.labelReviewCount, "Review Count");
    put(I18nKey.labelFullCustomCount, "Full Custom Count");
    put(I18nKey.labelNoContent, "No content yet");
    put(I18nKey.labelJsonErrorSaveFailed, "JSON format error, failed to save.");
    put(I18nKey.labelImportFailed, "Import failed");
    put(I18nKey.labelImportSuccess, "Import success");
    put(I18nKey.labelImportMojo, "Importing new data will clear all existing data");
    put(I18nKey.labelImportMojoTips, "Input red words to continue");
    put(I18nKey.labelImportCanceled, "Import canceled");
    put(I18nKey.labelImporting, "Importing...");
    put(I18nKey.labelExporting, "Exporting...");
    put(I18nKey.labelExecuting, "Executing...");
    put(I18nKey.labelDeleting, "Deleting...");
    put(I18nKey.labelSaving, "Saving...");
    put(I18nKey.labelSelectDirectoryToSave, "Select a directory to save %s");
    put(I18nKey.labelFileSaved, "The file has been saved.");
    put(I18nKey.labelSaveSuccess, "Save success : %s");
    put(I18nKey.labelDirectoryPermissionDenied, "Please select another directory. No permission to save to this directory: %s");
    put(I18nKey.labelSaved, "Save success");
    put(I18nKey.labelSaveCancel, "Save canceled");
    put(I18nKey.labelStoragePermissionDenied, "Storage permission has been denied. Please enable storage permission in the settings.");
    put(I18nKey.labelLearned, "Learned: %s");
    put(I18nKey.labelTotal, "Total: %s");
    put(I18nKey.labelProgress, "Progress");
    put(I18nKey.labelMonth, "Month");
    put(I18nKey.labelAdjustLearnProgress, "Adjust the learning progress.");
    put(I18nKey.labelAdjustLearnProgressDesc, "Current progress is %s, please adjust your learning progress.");
    put(I18nKey.labelPleaseInputUnSignNumber, "Please enter a number greater than or equal to 0.");
    put(I18nKey.labelReset, "Reset");
    put(I18nKey.labelResetAllDesc, "All tasks for today will be reset. Do you want to continue?");
    put(I18nKey.labelResetLearnDesc, "The learning tasks will be reset. Do you want to continue?");
    put(I18nKey.labelResetReviewDesc, "The review tasks will be reset. Do you want to continue?");
    put(I18nKey.labelResetFullCustomDesc, "The full custom tasks will be deleted. Do you want to continue?");
    put(I18nKey.labelConfigSettingsForEl, "Learn Config");
    put(I18nKey.labelConfigSettingsForElDesc, "Arrange study sessions according to the Ebbinghaus forgetting curve.");
    put(I18nKey.labelConfigSettingsForRel, "Review Config");
    put(I18nKey.labelConfigSettingsForRelDesc, "Make arrangements for reviewing previous studies.");
    put(I18nKey.labelElConfig0000, "Organize Level %s, quantity is unlimited (unlimited per group)");
    put(I18nKey.labelElConfig0001, "Organize Level %s, quantity is unlimited (%s per group)");
    put(I18nKey.labelElConfig0010, "Organize Level %s, quantity is %s (unlimited per group)");
    put(I18nKey.labelElConfig0011, "Organize Level %s, quantity is %s (%s per group)");
    put(I18nKey.labelElConfig0100, "Organize Level from %s to %s, quantity is unlimited. (unlimited per group)");
    put(I18nKey.labelElConfig0101, "Organize Level from %s to %s, quantity is unlimited. (%s per group)");
    put(I18nKey.labelElConfig0110, "Organize Level from %s to %s, quantity is %s (unlimited per group)");
    put(I18nKey.labelElConfig0111, "Organize Level from %s to %s, quantity is %s (%s per group)");
    put(I18nKey.labelElConfig1000, "Randomly organize Level %s, quantity is unlimited (unlimited per group)");
    put(I18nKey.labelElConfig1001, "Randomly organize Level %s, quantity is unlimited (%s per group)");
    put(I18nKey.labelElConfig1010, "Randomly organize Level %s, quantity is %s (unlimited per group)");
    put(I18nKey.labelElConfig1011, "Randomly organize Level %s, quantity is %s (%s per group)");
    put(I18nKey.labelElConfig1100, "Randomly organize Level from %s to %s, quantity is unlimited (unlimited per group)");
    put(I18nKey.labelElConfig1101, "Randomly organize Level from %s to %s, quantity is unlimited (%s per group)");
    put(I18nKey.labelElConfig1110, "Randomly organize Level from %s to %s, quantity is %s (unlimited per group)");
    put(I18nKey.labelElConfig1111, "Randomly organize Level from %s to %s, quantity is %s (%s per group)");
    put(I18nKey.labelRelConfig0, "The %sth review covers the content from %s days ago, starting from %s. (unlimited per group)");
    put(I18nKey.labelRelConfig1, "The %sth review covers the content from %s days ago, starting from %s. (%s per group)");
    put(I18nKey.labelFullCustomConfig, "Start from segment @1, lesson @2 of the content @0, and plan @3 segment (unlimited per group).");
    put(I18nKey.labelElRandom, "Random");
    put(I18nKey.labelElToLevel, "End Level");
    put(I18nKey.labelElLevel, "Start Level");
    put(I18nKey.labelElLearnCount, "Learn Count");
    put(I18nKey.labelRelBefore, "How many days ago");
    put(I18nKey.labelRelFrom, "Start from");
    put(I18nKey.labelLearnCountPerGroup, "Number per group");
    put(I18nKey.labelFinish, "Finish");
    put(I18nKey.labelALL, "ALL");
    put(I18nKey.labelSavingConfirm, "Are you sure to save?");
    put(I18nKey.labelConfigChange, "Do you want to save the changes you made?");
    put(I18nKey.labelTextChange, "The text changed, do you want to save?");
    put(I18nKey.labelResetConfig, "The config will be reset. Are you sure?");
    put(I18nKey.labelDetailConfig, "Config Detail");
    put(I18nKey.labelDetail, "Detail");
    put(I18nKey.labelCopyConfig, "Copy Config");
    put(I18nKey.labelDeleteConfig, "Delete Config");
    put(I18nKey.labelCopyText, "Copy Text");
    put(I18nKey.labelResetPassword, "Reset Password");
    put(I18nKey.labelResetConfigDesc, "After resetting the configuration, the system's default configuration will be used.");
    put(I18nKey.labelOnTapError, "Please press and hold the button to confirm");
    put(I18nKey.labelSetMaskTips, "Swipe left to increase the height of the barrier.");
    put(I18nKey.labelQrCodeContentCopiedToClipboard, "QR code content copied to clipboard");
    put(I18nKey.labelCopiedToClipboard, "Copied to clipboard");
    put(I18nKey.labelShouldLinkToTheContentBeAdded, "Should the link to the content be added?");
    put(I18nKey.labelTooMuchData, "Too much data! %s");
    put(I18nKey.labelDataDuplication, "Data duplication!");
    put(I18nKey.labelDataAnomaly, "Data anomaly! %s");
    put(I18nKey.labelDataAnomalyWithArg, "Data anomaly! %s");
    put(I18nKey.labelRemoteImport, "Remote import");
    put(I18nKey.labelLocalZipImport, "Local ZIP import");
    put(I18nKey.labelLocalMediaImport, "Local media import");
    put(I18nKey.labelLocalImportCancel, "Local Import is Canceled");
    put(I18nKey.labelSegmentRemoved, "The corresponding learning segment has been removed. It is recommended to back up your data first, then click \"Confirm\" to delete the related data.");
    put(I18nKey.labelDocNotBeDownloaded, "The content (%s) is not downloaded");
    put(I18nKey.labelDocCantBeFound, "The content (%s) cannot be found");
    put(I18nKey.labelInputPathError, "The inputting path is error");
    put(I18nKey.labelScheduleCount, "Count");
    put(I18nKey.labelFrom, "From");
    put(I18nKey.labelLesson, "Lesson");
    put(I18nKey.labelSegment, "Segment");
    put(I18nKey.labelSegmentName, "Segment");
    put(I18nKey.labelIgnorePunctuation, "Ignore Punctuation");
    put(I18nKey.labelMatchType, "Match Type");
    put(I18nKey.labelSkipCharacter, "Enter This Char To Skip");
    put(I18nKey.labelEnableEditSegment, "Enable Edit Segment");
    put(I18nKey.labelGameId, "Game ID");
    put(I18nKey.labelOnlineUserNumber, "Online User Number");
    put(I18nKey.labelAllowRegisterNumber, "Allow Reg Number");
    put(I18nKey.labelQuestion, "Question");
    put(I18nKey.labelAnswer, "Answer");
    put(I18nKey.labelQuestionAndAnswer, "Q&A");
    put(I18nKey.labelCopyMode, "Copy Mode");
    put(I18nKey.labelWord, "Word");
    put(I18nKey.labelSingle, "Single");
    put(I18nKey.labelAll, "All");
    put(I18nKey.labelSetLevel, "Level");
    put(I18nKey.labelSetNextLearnDate, "Next Learning Date");
    put(I18nKey.labelSummary, "Summary");
    put(I18nKey.labelTodayLearning, "Today Learning");
    put(I18nKey.labelTotalLearning, "Total Learning");
    put(I18nKey.labelTodayTime, "Today Time");
    put(I18nKey.labelTotalTime, "Total Time");
    put(I18nKey.labelMin, "Min");
    put(I18nKey.labelSeg, "Seg");
    put(I18nKey.labelNote, "Note");
    put(I18nKey.labelShare, "Share");
    put(I18nKey.labelCalendar, "Calendar");
    put(I18nKey.labelCopyTemplateCount, "Copy Template Count");
    put(I18nKey.labelSegmentNeedToContainAnswer, "Segment Need To Contain Answer");
    put(I18nKey.labelSegmentKeyDuplicated, "Segment Key Duplicated: %s");
    put(I18nKey.labelKey, "Key");
    put(I18nKey.labelContent, "Content");
    put(I18nKey.labelPosition, "Position");
    put(I18nKey.labelSortBy, "Sort by");
    put(I18nKey.labelSortProgressAsc, "Progress (Asc)");
    put(I18nKey.labelSortProgressDesc, "Progress (Desc)");
    put(I18nKey.labelSortPositionAsc, "Position (Asc)");
    put(I18nKey.labelSortPositionDesc, "Position (Desc)");
    put(I18nKey.labelSortNextLearnDateAsc, "Next Learning Date (Asc)");
    put(I18nKey.labelSortNextLearnDateDesc, "Next Learning Date (Desc)");
    put(I18nKey.labelFindUnnecessarySegments, "Find Unnecessary Segments");
    put(I18nKey.labelSearch, "Search...");
    put(I18nKey.labelNotFoundSegment, "not found segment (%s)");
    put(I18nKey.labelSettingLearningProgressWarning, "Setting the learning progress here will not create a learning record");
    put(I18nKey.labelContentsHaveUnnecessarySegments, "Contents have unnecessary segments");
    put(I18nKey.btnHandleNow, "Handle Now");
    put(I18nKey.btnStart, "Start");
    put(I18nKey.btnAddSchedule, "Add Schedule");
    put(I18nKey.btnConfigSettings, "Config Settings");
    put(I18nKey.btnSet, "Set");
    put(I18nKey.btnUse, "Use");
    put(I18nKey.btnSetHead, "Set head");
    put(I18nKey.btnSetTail, "Set tail");
    put(I18nKey.btnExtendTail, "Extend tail");
    put(I18nKey.btnResetTail, "Reset tail");
    put(I18nKey.btnOther, "Other");
    put(I18nKey.btnCut, "Cut and retain front and back");
    put(I18nKey.btnDeleteCurr, "Delete current");
    put(I18nKey.btnCancel, "Cancel");
    put(I18nKey.btnContinue, "Continue");
    put(I18nKey.btnOk, "Ok");
    put(I18nKey.btnDelete, "Delete");
    put(I18nKey.btnShare, "Share");
    put(I18nKey.btnScan, "Scan");
    put(I18nKey.btnEditTrack, "Edit Track");
    put(I18nKey.btnEditNote, "Edit Note");
    put(I18nKey.btnGameMode, "Game Mode");
    put(I18nKey.btnConcentration, "Concentration");
    put(I18nKey.btnAdd, "Add");
    put(I18nKey.btnReset, "Reset");
    put(I18nKey.btnCopy, "Copy");
    put(I18nKey.btnDownload, "Download");
    put(I18nKey.btnLearn, "Learn");
    put(I18nKey.btnBrowse, "Browse");
    put(I18nKey.btnExamine, "Examine");
    put(I18nKey.btnReview, "Review");
    put(I18nKey.btnFullCustom, "Full Custom");
    put(I18nKey.btnRepeat, "Repeat");
    put(I18nKey.btnSchedule, "Schedule");
    put(I18nKey.btnShow, "SHOW");
    put(I18nKey.btnTips, "TIPS");
    put(I18nKey.btnUnknown, "UNKNOWN");
    put(I18nKey.btnKnow, "KNOW");
    put(I18nKey.btnError, "ERROR");
    put(I18nKey.btnNext, "NEXT");
    put(I18nKey.btnPrevious, "PREV");
    put(I18nKey.btnFinish, "FINISH");
    put(I18nKey.btnExport, "Export");
    put(I18nKey.btnImport, "Import");
    put(I18nKey.btnSave, "Save");
    put(I18nKey.btnClose, "Close");
    put(I18nKey.btnCheck, "CHECK");
    put(I18nKey.btnEditSegment, "Edit Segment");
  }
}
