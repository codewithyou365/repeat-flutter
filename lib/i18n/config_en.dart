library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigEn extends Config {
  ConfigEn({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "Repeat");
    put(I18nKey.settings, "Settings");
    put(I18nKey.content, "Content");
    put(I18nKey.contentShare, "Content-Share");
    put(I18nKey.statistic, "Stats");
    put(I18nKey.statisticLearn, "Stats-Learn");
    put(I18nKey.statisticReview, "Stats-Review");
    put(I18nKey.language, "Language");
    put(I18nKey.theme, "Theme");
    put(I18nKey.data, "Data");
    put(I18nKey.themeDark, "Dart");
    put(I18nKey.themeLight, "Light");
    put(I18nKey.labelDeveloping, "Developing");
    put(I18nKey.labelTitle, "Title");
    put(I18nKey.labelSelectClassroom, "Select Classroom");
    put(I18nKey.labelDeleteClassroom, "Please confirm to delete \n this classroom : %s");
    put(I18nKey.labelClassroomName, "Classroom Name");
    put(I18nKey.labelClassroomNameEmpty, "The classroom name cannot be empty");
    put(I18nKey.labelClassroomNameError, "The classroom name should be 3 letters or less and consist of alphanumeric characters.");
    put(I18nKey.labelClassroomNameDuplicated, "The classroom name is duplicated.");
    put(I18nKey.labelDelete, "Delete !");
    put(I18nKey.labelUrl, "URL");
    put(I18nKey.labelOriginalAddress, "Original address");
    put(I18nKey.labelLanAddress, "LAN address");
    put(I18nKey.labelDownloadFirstBeforeSharing, "Please download first before sharing.");
    put(I18nKey.labelAddContentIndex, "Add content index");
    put(I18nKey.labelEditContentIndex, "Edit content index");
    put(I18nKey.labelDeleteContentIndex, "Please confirm to delete content index\n\n%s");
    put(I18nKey.labelDownloadContent, "Download content");
    put(I18nKey.labelScheduleContent, "Add learning task with %s segments.");
    put(I18nKey.labelNoLearningContent, "There is no learning content available.");
    put(I18nKey.labelResetLearningContent, "The learning content will be reset in %s");
    put(I18nKey.labelTips, "Tips");
    put(I18nKey.labelNoContent, "No content yet");
    put(I18nKey.labelImportFailed, "Import failed");
    put(I18nKey.labelImportSuccess, "Import success");
    put(I18nKey.labelImportMojo, "Importing new data will clear all existing data");
    put(I18nKey.labelImportMojoTips, "Input red words to continue");
    put(I18nKey.labelImportCanceled, "Import canceled");
    put(I18nKey.labelImporting, "Importing...");
    put(I18nKey.labelExporting, "Exporting...");
    put(I18nKey.labelExecuting, "Executing...");
    put(I18nKey.labelResetLearn, "Reset Learn");
    put(I18nKey.labelResetLearnDesc, "After executing the reset function, the unfinished tasks for today will be reset. Do you want to continue?");
    put(I18nKey.labelConfigSettingsForEl, "Learn Config");
    put(I18nKey.labelConfigSettingsForElDesc, "Arrange study sessions according to the Ebbinghaus forgetting curve.");
    put(I18nKey.labelConfigSettingsForRel, "Review Config");
    put(I18nKey.labelConfigSettingsForRelDesc, "Make arrangements for reviewing previous studies.");
    put(I18nKey.labelElConfig0000, "Organize Level %s quantities: unlimited (unlimited per group)");
    put(I18nKey.labelElConfig0001, "Organize Level %s quantities: unlimited (%s per group)");
    put(I18nKey.labelElConfig0010, "Organize Level %s quantities: %s (unlimited per group)");
    put(I18nKey.labelElConfig0011, "Organize Level %s quantities: %s (%s per group)");
    put(I18nKey.labelElConfig0100, "Organize Level %s and subsequent quantities: unlimited (unlimited per group)");
    put(I18nKey.labelElConfig0101, "Organize Level %s and subsequent quantities: unlimited (%s per group)");
    put(I18nKey.labelElConfig0110, "Organize Level %s and subsequent quantities: %s (unlimited per group)");
    put(I18nKey.labelElConfig0111, "Organize Level %s and subsequent quantities: %s (%s per group)");
    put(I18nKey.labelElConfig1000, "Randomly organize Level %s quantities: unlimited (unlimited per group)");
    put(I18nKey.labelElConfig1001, "Randomly organize Level %s quantities: unlimited (%s per group)");
    put(I18nKey.labelElConfig1010, "Randomly organize Level %s quantities: %s (unlimited per group)");
    put(I18nKey.labelElConfig1011, "Randomly organize Level %s quantities: %s (%s per group)");
    put(I18nKey.labelElConfig1100, "Randomly organize Level %s and subsequent quantities: unlimited (unlimited per group)");
    put(I18nKey.labelElConfig1101, "Randomly organize Level %s and subsequent quantities: unlimited (%s per group)");
    put(I18nKey.labelElConfig1110, "Randomly organize Level %s and subsequent quantities: %s (unlimited per group)");
    put(I18nKey.labelElConfig1111, "Randomly organize Level %s and subsequent quantities: %s (%s per group)");
    put(I18nKey.labelRelConfig0, "The %sth review will cover the content from %s days ago, starting from %s. (unlimited per group)");
    put(I18nKey.labelRelConfig1, "The %sth review will cover the content from %s days ago, starting from %s. (%s per group)");
    put(I18nKey.labelElRandom, "Random");
    put(I18nKey.labelElExtend, "And subsequent");
    put(I18nKey.labelElLevel, "Level");
    put(I18nKey.labelElLearnCount, "Learn count");
    put(I18nKey.labelRelBefore, "How many days ago");
    put(I18nKey.labelRelFrom, "Start from");
    put(I18nKey.labelLearnCountPerGroup, "Number per group");
    put(I18nKey.labelFinish, "Finish");
    put(I18nKey.labelAll, "ALL");
    put(I18nKey.labelSavingConfirm, "Are you sure to save?");
    put(I18nKey.labelConfigChange, "Do you want to save the changes you made?");
    put(I18nKey.labelResetConfig, "Reset Config");
    put(I18nKey.labelResetConfigDesc, "After resetting the configuration, the system’s default configuration will be used.");
    put(I18nKey.labelOnTapError, "Please press and hold the button to confirm");
    put(I18nKey.labelSetMaskTips, "Swipe left to increase the height of the barrier.");
    put(I18nKey.labelQrCodeContentCopiedToClipboard, "QR code content copied to clipboard");
    put(I18nKey.btnCancel, "Cancel");
    put(I18nKey.btnOk, "Ok");
    put(I18nKey.btnDelete, "Delete");
    put(I18nKey.btnShare, "Share");
    put(I18nKey.btnEdit, "Edit");
    put(I18nKey.btnAdd, "Add");
    put(I18nKey.btnCopy, "Copy");
    put(I18nKey.btnDownload, "Download");
    put(I18nKey.btnLearn, "Learn");
    put(I18nKey.btnReview, "Review");
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
  }
}
