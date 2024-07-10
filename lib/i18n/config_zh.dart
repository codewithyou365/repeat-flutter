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
    put(I18nKey.labelDeveloping, "开发中");
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
    put(I18nKey.labelExecuting, "执行中...");
    put(I18nKey.labelResetLearn, "重置学习内容");
    put(I18nKey.labelResetLearnDesc, "执行重置后，将重置今日未完成的任务，是否继续？");
    put(I18nKey.labelConfigSettingsForEl, "EL设置");
    put(I18nKey.labelConfigSettingsForElDesc, "EL 是 ebbinghaus learning 缩写，以艾宾浩斯遗忘曲线进行安排学习。");
    put(I18nKey.labelConfigSettingsForRel, "REL设置");
    put(I18nKey.labelConfigSettingsForRelDesc, "REL 是 review ebbinghaus learning 缩写， 对之前的学习，进行回顾安排的配置。");
    put(I18nKey.labelElConfig0000, "安排%s级数量不限 (每组不限)");
    put(I18nKey.labelElConfig0001, "安排%s级数量不限 (每组%s个)");
    put(I18nKey.labelElConfig0010, "安排%s级数量: %s (每组不限)");
    put(I18nKey.labelElConfig0011, "安排%s级数量: %s (每组%s个)");
    put(I18nKey.labelElConfig0100, "安排%s级及以后数量不限 (每组不限)");
    put(I18nKey.labelElConfig0101, "安排%s级及以后数量不限 (每组%s个)");
    put(I18nKey.labelElConfig0110, "安排%s级及以后数量: %s (每组不限)");
    put(I18nKey.labelElConfig0111, "安排%s级及以后数量: %s (每组%s个)");
    put(I18nKey.labelElConfig1000, "随机安排%s级数量不限 (每组不限)");
    put(I18nKey.labelElConfig1001, "随机安排%s级数量不限 (每组%s个)");
    put(I18nKey.labelElConfig1010, "随机安排%s级数量: %s (每组不限)");
    put(I18nKey.labelElConfig1011, "随机安排%s级数量: %s (每组%s个)");
    put(I18nKey.labelElConfig1100, "随机安排%s级及以后数量不限 (每组不限)");
    put(I18nKey.labelElConfig1101, "随机安排%s级及以后数量不限 (每组%s个)");
    put(I18nKey.labelElConfig1110, "随机安排%s级及以后数量: %s (每组不限)");
    put(I18nKey.labelElConfig1111, "随机安排%s级及以后数量: %s (每组%s个)");
    put(I18nKey.labelRelConfig00, "第%s次回顾%s天以前的内容，从%s开始 (每组不限)");
    put(I18nKey.labelRelConfig01, "第%s次回顾%s天以前的内容，从%s开始 (每组%s个)");
    put(I18nKey.labelRelConfig10, "第%s次回顾%s天以前的内容，从%s开始\n如果需要进行追赶,每次追赶%s天的量 (每组不限)");
    put(I18nKey.labelRelConfig11, "第%s次回顾%s天以前的内容，从%s开始\n如果需要进行追赶,每次追赶%s天的量 (每组%s个)");
    put(I18nKey.labelFinish, "完成");
    put(I18nKey.labelSavingConfirm, "是否确定保存？");
    put(I18nKey.labelConfigChange, "配置已改变是否保存？");
    put(I18nKey.labelResetConfig, "重置配置");
    put(I18nKey.labelResetConfigDesc, "执行重置配置后，将使用系统默认的配置？");
    put(I18nKey.btnCancel, "取消");
    put(I18nKey.btnOk, "确定");
    put(I18nKey.btnDelete, "删除");
    put(I18nKey.btnEdit, "编辑");
    put(I18nKey.btnAdd, "新增");
    put(I18nKey.btnCopy, "复制");
    put(I18nKey.btnDownload, "下载");
    put(I18nKey.btnLearn, "学习");
    put(I18nKey.btnReview, "回顾");
    put(I18nKey.btnRepeat, "重复");
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
