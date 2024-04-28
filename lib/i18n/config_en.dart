library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigEn extends Config {
  ConfigEn({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "Repeat");
    put(I18nKey.settings, "Settings");
    put(I18nKey.content, "Content");
    put(I18nKey.statistic, "Stats");
    put(I18nKey.language, "Language");
    put(I18nKey.theme, "Theme");
    put(I18nKey.themeDark, "Dart");
    put(I18nKey.themeLight, "Light");
    put(I18nKey.labelUrl, "URL");
    put(I18nKey.labelAddContentIndex, "Add content index");
    put(I18nKey.labelEditContentIndex, "Edit content index");
    put(I18nKey.labelDeleteContentIndex, "Please confirm to delete content index\n\n%s");
    put(I18nKey.labelDownloadContent, "Download content");
    put(I18nKey.labelScheduleContent, "Add learning task with %s segments.");
    put(I18nKey.labelNoLearningContent, "There is no learning content available at this time.");
    put(I18nKey.labelResetLearningContent, "The learning content will be reset in %s");
    put(I18nKey.labelTips, "Tips");
    put(I18nKey.btnCancel, "Cancel");
    put(I18nKey.btnOk, "Ok");
    put(I18nKey.btnDelete, "Delete");
    put(I18nKey.btnEdit, "Edit");
    put(I18nKey.btnAdd, "Add");
    put(I18nKey.btnCopy, "Copy");
    put(I18nKey.btnDownload, "Download");
    put(I18nKey.btnLearn, "Learn");
    put(I18nKey.btnReview, "Review");
    put(I18nKey.btnSchedule, "Schedule");
    put(I18nKey.btnShow, "SHOW");
    put(I18nKey.btnUnknown, "UNKNOWN");
    put(I18nKey.btnKnow, "KNOW");
    put(I18nKey.btnError, "ERROR");
    put(I18nKey.btnNext, "NEXT");
  }
}
