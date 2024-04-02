library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigZh extends Config {
  ConfigZh({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "重复");
    put(I18nKey.settings, "设置");
    put(I18nKey.content, "内容");
    put(I18nKey.statistic, "统计");
    put(I18nKey.language, "语言");
    put(I18nKey.theme, "主题");
    put(I18nKey.themeDark, "暗色主题");
    put(I18nKey.themeLight, "亮色主题");
    put(I18nKey.labelUrl, "地址");
    put(I18nKey.labelAddContentIndex, "新增内容索引");
    put(I18nKey.labelEditContentIndex, "编辑内容索引");
    put(I18nKey.labelDeleteContentIndex, "确定删除内容索引\n\n%s");
    put(I18nKey.labelDownloadContent, "下载内容");
    put(I18nKey.btnCancel, "取消");
    put(I18nKey.btnOk, "确定");
    put(I18nKey.btnDelete, "删除");
    put(I18nKey.btnEdit, "编辑");
    put(I18nKey.btnAdd, "新增");
    put(I18nKey.btnCopy, "复制");
    put(I18nKey.btnDownload, "下载");
    put(I18nKey.btnReview, "回顾");
    put(I18nKey.btnRepeat, "重复");
  }
}
