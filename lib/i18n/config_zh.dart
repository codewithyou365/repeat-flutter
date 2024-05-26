library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigZh extends Config {
  ConfigZh({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "重复");
    put(I18nKey.settings, "设置");
    put(I18nKey.content, "内容");
    put(I18nKey.statistic, "统计");
    put(I18nKey.statisticLearn, "统计-学习");
    put(I18nKey.statisticReview, "统计-回顾");
    put(I18nKey.language, "语言");
    put(I18nKey.theme, "主题");
    put(I18nKey.data, "数据");
    put(I18nKey.themeDark, "暗色主题");
    put(I18nKey.themeLight, "亮色主题");
    put(I18nKey.labelSelectClassroom, "选择课堂");
    put(I18nKey.labelDeleteClassroom, "请确定删除这个课堂 : %s");
    put(I18nKey.labelClassroomName, "课堂名称");
    put(I18nKey.labelClassroomNameEmpty, "课堂名字应不能为空");
    put(I18nKey.labelClassroomNameError, "课堂名字应为 3 个字母或更少，并且由字母数字字符组成。");
    put(I18nKey.labelClassroomNameDuplicated, "课堂名字重复。");
    put(I18nKey.labelDelete, "删除 ！");
    put(I18nKey.labelUrl, "地址");
    put(I18nKey.labelAddContentIndex, "新增内容索引");
    put(I18nKey.labelEditContentIndex, "编辑内容索引");
    put(I18nKey.labelDeleteContentIndex, "请确定删除内容索引\n\n%s");
    put(I18nKey.labelDownloadContent, "下载内容");
    put(I18nKey.labelScheduleContent, "添加学习任务 %s 个单位");
    put(I18nKey.labelNoLearningContent, "现在没有学习内容");
    put(I18nKey.labelResetLearningContent, "在 %s 后，将重置学习内容");
    put(I18nKey.labelTips, "提示");
    put(I18nKey.labelNoContent, "暂无内容");
    put(I18nKey.labelImportFailed, "导入失败");
    put(I18nKey.labelImportSuccess, "导入成功");
    put(I18nKey.labelImportMojo, "导入新数据将清除所有现有数据");
    put(I18nKey.labelImportMojoTips, "输入红色文字以继续");
    put(I18nKey.labelImportCanceled, "导入取消");
    put(I18nKey.labelImporting, "导入中...");
    put(I18nKey.labelExporting, "导出中...");
    put(I18nKey.btnCancel, "取消");
    put(I18nKey.btnOk, "确定");
    put(I18nKey.btnDelete, "删除");
    put(I18nKey.btnEdit, "编辑");
    put(I18nKey.btnAdd, "新增");
    put(I18nKey.btnCopy, "复制");
    put(I18nKey.btnDownload, "下载");
    put(I18nKey.btnLearn, "学习");
    put(I18nKey.btnReview, "回顾");
    put(I18nKey.btnSchedule, "安排");
    put(I18nKey.btnShow, "展示");
    put(I18nKey.btnTips, "提示");
    put(I18nKey.btnUnknown, "不知道");
    put(I18nKey.btnKnow, "知道");
    put(I18nKey.btnError, "错误");
    put(I18nKey.btnNext, "下一个");
    put(I18nKey.btnFinish, "完成");
    put(I18nKey.btnExport, "导出");
    put(I18nKey.btnImport, "导入");
  }
}
