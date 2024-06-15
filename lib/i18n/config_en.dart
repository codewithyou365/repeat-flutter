library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigEn extends Config {
  ConfigEn({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "Repeat");
    put(I18nKey.settings, "Settings");
    put(I18nKey.content, "Content");
    put(I18nKey.statistic, "Stats");
    put(I18nKey.statisticLearn, "Stats-Learn");
    put(I18nKey.statisticReview, "Stats-Review");
    put(I18nKey.language, "Language");
    put(I18nKey.theme, "Theme");
    put(I18nKey.data, "Data");
    put(I18nKey.themeDark, "Dart");
    put(I18nKey.themeLight, "Light");
    put(I18nKey.labelSelectClassroom, "Select Classroom");
    put(I18nKey.labelDeleteClassroom, "Please confirm to delete \n this classroom : %s");
    put(I18nKey.labelClassroomName, "Classroom Name");
    put(I18nKey.labelClassroomNameEmpty, "The classroom name cannot be empty");
    put(I18nKey.labelClassroomNameError, "The classroom name should be 3 letters or less and consist of alphanumeric characters.");
    put(I18nKey.labelClassroomNameDuplicated, "The classroom name is duplicated.");
    put(I18nKey.labelDelete, "Delete !");
    put(I18nKey.labelUrl, "URL");
    put(I18nKey.labelAddContentIndex, "Add content index");
    put(I18nKey.labelEditContentIndex, "Edit content index");
    put(I18nKey.labelDeleteContentIndex, "Please confirm to delete content index\n\n%s");
    put(I18nKey.labelDownloadContent, "Download content");
    put(I18nKey.labelScheduleContent, "Add learning task with %s segments.");
    put(I18nKey.labelNoLearningContent, "There is no learning content available at this time.");
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
    put(I18nKey.labelResetLearn, "Reset");
    put(I18nKey.labelResetLearnDesc, "After executing the reset function, the unfinished tasks for today will be reset. Do you want to continue?");
    put(I18nKey.labelFinish, "Finish");
    put(I18nKey.btnCancel, "Cancel");
    put(I18nKey.btnOk, "Ok");
    put(I18nKey.btnDelete, "Delete");
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
    put(I18nKey.btnFinish, "FINISH");
    put(I18nKey.btnExport, "Export");
    put(I18nKey.btnImport, "Import");
  }
}
